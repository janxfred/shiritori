const sharp = require("sharp");
const path = require("path");
const fs = require("fs");

const basePath = path.join(__dirname, "assets/launcher_icon");
const frontPath = path.join(basePath, "icon_front.png");
const bgPath = path.join(basePath, "BG.png");

async function process() {
  try {
    console.log("Starting...");
    const targetSize = 1024;

    // Use full size (100%) to maximize visibility
    // Some cropping might occur on corners but face is central
    const scaleFactor = 1.0;
    const maxDim = Math.floor(targetSize * scaleFactor);

    // 1. Process Foreground
    const front = sharp(frontPath);
    const frontMeta = await front.metadata();
    console.log(
      `Front: ${frontMeta.width}x${frontMeta.height}, Scale: ${scaleFactor}`,
    );

    // Resize strict fit within maxDim maintaining aspect ratio
    const frontResized = await front
      .resize({
        width: maxDim,
        height: maxDim,
        fit: "contain",
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .toBuffer();

    // Compose onto 1024x1024 transparent canvas
    const frontSquare = await sharp({
      create: {
        width: targetSize,
        height: targetSize,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      },
    })
      .composite([{ input: frontResized, gravity: "center" }])
      .png()
      .toFile(path.join(basePath, "icon_foreground_v2.png"));
    console.log("Saved foreground v2");

    // 2. Process Background (Stretch)
    const bgSquareBuffer = await sharp(bgPath)
      .resize({
        width: targetSize,
        height: targetSize,
        fit: "fill",
      })
      .png()
      .toBuffer();

    await sharp(bgSquareBuffer).toFile(
      path.join(basePath, "icon_background_v2.png"),
    );
    console.log("Saved background v2");

    // 3. Combined
    // Composite Front on top of BG
    await sharp(bgSquareBuffer)
      .composite([
        {
          input: await sharp(
            path.join(basePath, "icon_foreground_v2.png"),
          ).toBuffer(),
        },
      ])
      .toFile(path.join(basePath, "icon_ios_v2.png"));

    console.log("Saved combined v2");
  } catch (e) {
    console.error("Error:", e);
    process.exit(1);
  }
}

process();
