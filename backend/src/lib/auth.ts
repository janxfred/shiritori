import crypto from "node:crypto";

const PBKDF2_ITERATIONS = 100_000;
const PBKDF2_KEYLEN = 32;
const PBKDF2_DIGEST = "sha256";

function base64urlEncode(buf: Buffer): string {
  return buf
    .toString("base64")
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function base64urlDecode(input: string): Buffer {
  const normalized = input.replaceAll("-", "+").replaceAll("_", "/");
  const pad = normalized.length % 4;
  const padded = pad === 0 ? normalized : normalized + "=".repeat(4 - pad);
  return Buffer.from(padded, "base64");
}

export async function hashPassword(params: {
  password: string;
}): Promise<string> {
  const { password } = params;
  const salt = crypto.randomBytes(16);
  const derivedKey = await new Promise<Buffer>((resolve, reject) => {
    crypto.pbkdf2(
      password,
      salt,
      PBKDF2_ITERATIONS,
      PBKDF2_KEYLEN,
      PBKDF2_DIGEST,
      (err, key) => {
        if (err) return reject(err);
        resolve(key);
      }
    );
  });

  return [
    "pbkdf2",
    PBKDF2_DIGEST,
    String(PBKDF2_ITERATIONS),
    salt.toString("base64"),
    derivedKey.toString("base64"),
  ].join("$");
}

export async function verifyPassword(params: {
  password: string;
  passwordHash: string;
}): Promise<boolean> {
  const { password, passwordHash } = params;
  const parts = passwordHash.split("$");
  if (parts.length !== 5) return false;

  const [algo, digest, iterationsStr, saltB64, keyB64] = parts;
  if (algo !== "pbkdf2") return false;
  if (digest !== PBKDF2_DIGEST) return false;

  const iterations = Number(iterationsStr);
  if (!Number.isFinite(iterations) || iterations <= 0) return false;

  const salt = Buffer.from(saltB64, "base64");
  const expectedKey = Buffer.from(keyB64, "base64");

  const derivedKey = await new Promise<Buffer>((resolve, reject) => {
    crypto.pbkdf2(
      password,
      salt,
      iterations,
      expectedKey.length,
      digest,
      (err, key) => {
        if (err) return reject(err);
        resolve(key);
      }
    );
  });

  return crypto.timingSafeEqual(derivedKey, expectedKey);
}

function getTokenSecret(): string {
  const secret = process.env.AUTH_TOKEN_SECRET;
  if (secret && secret.length >= 16) return secret;

  if (process.env.NODE_ENV !== "production") {
    return "dev-secret-change-me";
  }

  throw new Error("AUTH_TOKEN_SECRET is not set");
}

export function signAuthToken(params: {
  userId: string;
  ttlSeconds?: number;
}): string {
  const { userId, ttlSeconds = 60 * 60 * 24 * 30 } = params; // 30 days
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + ttlSeconds;

  const payload = Buffer.from(
    JSON.stringify({ sub: userId, iat, exp }),
    "utf8"
  );
  const payloadB64 = base64urlEncode(payload);

  const sig = crypto
    .createHmac("sha256", getTokenSecret())
    .update(payloadB64)
    .digest();
  const sigB64 = base64urlEncode(sig);

  return `v1.${payloadB64}.${sigB64}`;
}

export function verifyAuthToken(params: {
  token: string;
}): { userId: string } | null {
  const { token } = params;
  const [v, payloadB64, sigB64] = token.split(".");
  if (v !== "v1" || !payloadB64 || !sigB64) return null;

  const expectedSig = crypto
    .createHmac("sha256", getTokenSecret())
    .update(payloadB64)
    .digest();

  const actualSig = base64urlDecode(sigB64);
  if (actualSig.length !== expectedSig.length) return null;
  if (!crypto.timingSafeEqual(actualSig, expectedSig)) return null;

  let payloadJson: unknown;
  try {
    payloadJson = JSON.parse(base64urlDecode(payloadB64).toString("utf8"));
  } catch {
    return null;
  }

  if (!payloadJson || typeof payloadJson !== "object") return null;
  if (!("sub" in payloadJson) || !("exp" in payloadJson)) return null;

  const userId = (payloadJson as { sub: unknown }).sub;
  const exp = (payloadJson as { exp: unknown }).exp;

  if (typeof userId !== "string") return null;
  if (typeof exp !== "number") return null;

  const now = Math.floor(Date.now() / 1000);
  if (now >= exp) return null;

  return { userId };
}
