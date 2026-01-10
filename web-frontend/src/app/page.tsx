'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { startGame, submitWord, checkTime } from '@/lib/game-api';
import type { AiLevel, GameSession, TurnResult } from '@/schemas/game.schema';

type GamePhase = 'title' | 'playing' | 'overtime_announce' | 'game_over';

/** 制限時間（ミリ秒）: 2分 */
const TIME_LIMIT_MS = 2 * 60 * 1000;

/** AIの応答遅延（ミリ秒） */
const AI_RESPONSE_DELAY_MS = 2000;

/** 延長戦告知表示時間（ミリ秒） */
const OVERTIME_ANNOUNCE_DELAY_MS = 3000;

/**
 * カタカナをひらがなに変換
 */
function katakanaToHiragana(str: string): string {
  return str.replace(/[\u30A1-\u30F6]/g, (match) => {
    return String.fromCharCode(match.charCodeAt(0) - 0x60);
  });
}

export default function HomePage() {
  const [phase, setPhase] = useState<GamePhase>('title');
  const [session, setSession] = useState<GameSession | null>(null);
  const [demonMessage, setDemonMessage] = useState<string>('');
  const [inputWord, setInputWord] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isAiThinking, setIsAiThinking] = useState(false);
  const [lastPlayerResult, setLastPlayerResult] = useState<TurnResult | null>(null);
  const [lastAiResult, setLastAiResult] = useState<TurnResult | null>(null);
  const [winner, setWinner] = useState<'player' | 'ai' | null>(null);
  const [isShaking, setIsShaking] = useState(false);
  const [selectedLevel, setSelectedLevel] = useState<AiLevel>(2);
  const [remainingTime, setRemainingTime] = useState<number>(TIME_LIMIT_MS);
  const historyRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // 履歴の自動スクロール
  useEffect(() => {
    if (historyRef.current) {
      historyRef.current.scrollTop = historyRef.current.scrollHeight;
    }
  }, [session?.history]);

  // タイマーの管理
  useEffect(() => {
    if (phase === 'playing' && session?.status === 'playing' && !isAiThinking) {
      // タイマー開始
      timerIntervalRef.current = setInterval(async () => {
        if (!session) return;

        // 残り時間を計算（ローカルで）
        const turnStarted = new Date(session.turnStartedAt).getTime();
        const now = Date.now();
        const elapsed = now - turnStarted;
        const remaining = Math.max(0, TIME_LIMIT_MS - elapsed);
        setRemainingTime(remaining);

        // 時間切れの場合、サーバーに確認
        if (remaining <= 0) {
          try {
            const result = await checkTime(session.id);
            if (result.expired && result.session) {
              setSession(result.session);
              setDemonMessage(result.message ?? '時間切れだ。');
              setWinner('ai');
              setPhase('game_over');
            }
          } catch (error) {
            console.error('時間チェックエラー:', error);
          }
        }
      }, 100);

      return () => {
        if (timerIntervalRef.current) {
          clearInterval(timerIntervalRef.current);
        }
      };
    }
  }, [phase, session, isAiThinking]);

  // ゲーム開始
  const handleStartGame = useCallback(async (level?: AiLevel) => {
    const aiLevel = level ?? selectedLevel;
    try {
      const response = await startGame(aiLevel);
      setLastPlayerResult(null);
      setLastAiResult(null);
      setWinner(null);
      setPhase('playing');
      
      // AI先攻の場合
      if (response.firstTurn === 'ai' && response.aiFirstMove) {
        // まずAI思考中を表示
        setSession({
          ...response.session,
          currentTurn: 'ai',
          expectedStartChar: response.startChar,
        });
        setDemonMessage(`我が先攻だ。「${response.startChar}」から始めるぞ…`);
        setIsAiThinking(true);
        
        // 2秒後にAIの結果を表示
        setTimeout(() => {
          setSession(response.session);
          setDemonMessage(response.message);
          setLastAiResult({
            word: response.aiFirstMove!.word,
            isValid: true,
            message: response.message,
            capturedChars: response.aiFirstMove!.capturedChars,
          });
          setIsAiThinking(false);
          setRemainingTime(TIME_LIMIT_MS);
          setTimeout(() => inputRef.current?.focus(), 100);
        }, AI_RESPONSE_DELAY_MS);
      } else {
        // プレイヤー先攻の場合
        setSession(response.session);
        setDemonMessage(response.message);
        setRemainingTime(TIME_LIMIT_MS);
        setIsAiThinking(false);
        setTimeout(() => inputRef.current?.focus(), 100);
      }
    } catch (error) {
      console.error('ゲーム開始エラー:', error);
    }
  }, [selectedLevel]);

  // 単語送信
  const handleSubmitWord = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    if (!session || !inputWord.trim() || isSubmitting || isAiThinking) return;

    setIsSubmitting(true);
    setLastPlayerResult(null);
    setLastAiResult(null);

    try {
      const response = await submitWord(session.id, inputWord.trim());
      setLastPlayerResult(response.playerResult);

      if (!response.playerResult.isValid) {
        setIsShaking(true);
        setTimeout(() => setIsShaking(false), 300);
        setDemonMessage(response.playerResult.message);
        setSession(response.session);

        if (response.gameOver) {
          setWinner(response.winner ?? null);
          setPhase('game_over');
        }
      } else if (response.aiResult) {
        // AIの応答がある場合、2秒待ってから表示
        setIsAiThinking(true);
        setDemonMessage('ふむ…考えさせてもらおう…');

        setTimeout(() => {
          setLastAiResult(response.aiResult!);
          setDemonMessage(response.aiResult!.message);
          setSession(response.session);
          setRemainingTime(response.session.remainingTimeMs);
          setIsAiThinking(false);

          if (response.gameOver) {
            setWinner(response.winner ?? null);
            setPhase('game_over');
          } else if (response.overtimeStarted) {
            // 延長戦開始
            setPhase('overtime_announce');
            setTimeout(() => {
              setPhase('playing');
              setTimeout(() => inputRef.current?.focus(), 100);
            }, OVERTIME_ANNOUNCE_DELAY_MS);
          }
        }, AI_RESPONSE_DELAY_MS);
      } else {
        setSession(response.session);
        if (response.gameOver) {
          setWinner(response.winner ?? null);
          setPhase('game_over');
        }
      }

      setInputWord('');
    } catch (error) {
      console.error('送信エラー:', error);
    } finally {
      setIsSubmitting(false);
    }
  }, [session, inputWord, isSubmitting, isAiThinking]);

  // 入力変更時にカタカナをひらがなに変換
  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const converted = katakanaToHiragana(e.target.value);
    setInputWord(converted);
  }, []);

  // 残り時間のフォーマット
  const formatTime = (ms: number) => {
    const totalSeconds = Math.ceil(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  // 残り時間の色
  const getTimeColor = () => {
    if (remainingTime <= 10000) return 'text-red-500 animate-pulse';
    if (remainingTime <= 30000) return 'text-orange-400';
    return 'text-demon-gold';
  };

  // レベル名
  const getLevelName = (level: AiLevel) => {
    switch (level) {
      case 1: return '初級';
      case 2: return '中級';
      case 3: return '上級';
    }
  };

  // 延長戦告知画面
  if (phase === 'overtime_announce') {
    return (
      <div className='min-h-screen flex flex-col items-center justify-center p-8'>
        <div className='text-center'>
          <h1 className='text-5xl md:text-7xl font-bold text-red-500 animate-pulse mb-8 tracking-wider'>
            延長戦
          </h1>
          <p className='text-demon-parchment text-2xl mb-4'>
            同点のため、決着をつける！
          </p>
          <p className='text-demon-gold text-lg italic'>
            「{demonMessage}」
          </p>
          <div className='mt-8'>
            <div className='flex justify-center gap-12'>
              <div className='text-center'>
                <p className='text-demon-parchment/60 text-sm'>汝の確保文字</p>
                <p className='text-demon-gold text-4xl font-bold'>{session?.playerCapturedChars.length ?? 0}</p>
              </div>
              <div className='text-demon-parchment text-4xl font-bold'>vs</div>
              <div className='text-center'>
                <p className='text-demon-parchment/60 text-sm'>悪魔の確保文字</p>
                <p className='text-red-400 text-4xl font-bold'>{session?.aiCapturedChars.length ?? 0}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // タイトル画面
  if (phase === 'title') {
    return (
      <div className='min-h-screen flex flex-col items-center justify-center p-8'>
        <div className='text-center'>
          {/* タイトル */}
          <h1 className='text-5xl md:text-7xl font-bold text-demon-gold animate-pulse-glow mb-4 tracking-wider'>
            悪魔的しりとり
          </h1>
          <p className='text-demon-parchment/80 text-lg md:text-xl mb-12 italic'>
            Demonic Word Chain
          </p>

          {/* 悪魔のシルエット */}
          <div className='relative w-48 h-48 mx-auto mb-12'>
            <svg viewBox='0 0 100 100' className='w-full h-full animate-float'>
              <defs>
                <radialGradient id='demonGlow' cx='50%' cy='50%' r='50%'>
                  <stop offset='0%' stopColor='#D4AF37' stopOpacity='0.3' />
                  <stop offset='100%' stopColor='#D4AF37' stopOpacity='0' />
                </radialGradient>
              </defs>
              <circle cx='50' cy='50' r='45' fill='url(#demonGlow)' />
              <ellipse cx='35' cy='45' rx='8' ry='5' fill='#3D0000' />
              <ellipse cx='65' cy='45' rx='8' ry='5' fill='#3D0000' />
              <circle cx='35' cy='45' r='3' fill='#D4AF37' className='animate-flicker' />
              <circle cx='65' cy='45' r='3' fill='#D4AF37' className='animate-flicker' />
              <path d='M25 30 L30 45 L20 42 Z' fill='#3D0000' />
              <path d='M75 30 L70 45 L80 42 Z' fill='#3D0000' />
              <path d='M35 65 Q50 75 65 65' fill='none' stroke='#D4AF37' strokeWidth='2' />
            </svg>
          </div>

          {/* レベル選択 */}
          <div className='demon-message rounded-lg p-6 mb-6 max-w-md mx-auto'>
            <h2 className='text-demon-gold font-bold text-lg mb-4'>悪魔の強さを選べ</h2>
            <div className='flex gap-4 justify-center'>
              {([1, 2, 3] as AiLevel[]).map((level) => (
                <button
                  key={level}
                  onClick={() => setSelectedLevel(level)}
                  className={`px-6 py-3 rounded-lg font-bold transition-all ${
                    selectedLevel === level
                      ? 'metallic-button text-demon-black'
                      : 'border-2 border-demon-gold/50 text-demon-parchment/80 hover:border-demon-gold hover:text-demon-gold'
                  }`}
                >
                  <div className='text-lg'>Lv.{level}</div>
                  <div className='text-xs opacity-80'>{getLevelName(level)}</div>
                </button>
              ))}
            </div>
            <p className='text-demon-parchment/60 text-xs mt-4'>
              {selectedLevel === 1 && '気まぐれな悪魔。ランダムに言葉を選ぶ。'}
              {selectedLevel === 2 && '狡猾な悪魔。時に賢く、時に愚かに振る舞う。'}
              {selectedLevel === 3 && '最強の悪魔。常に最善手を打つ。'}
            </p>
          </div>

          {/* ルール説明 */}
          <div className='demon-message rounded-lg p-6 mb-8 max-w-md mx-auto text-left'>
            <h2 className='text-demon-gold font-bold text-lg mb-3'>契約の条件</h2>
            <ul className='text-demon-parchment/90 space-y-2 text-sm'>
              <li>• 相手より先に使った文字を「確保」できる</li>
              <li>• 確保された文字は2文字目以降に使えない</li>
              <li>• 2回お手つきで即敗北</li>
              <li>• 「ん」で終わる言葉は禁忌</li>
              <li>• 小さい文字は大きい文字と同一とみなす</li>
              <li>• <span className='text-red-400'>制限時間は2分。時間切れで敗北。</span></li>
              <li>• <span className='text-yellow-400'>10ラウンド終了時、確保文字が多い方が敗北</span></li>
            </ul>
          </div>

          {/* 開始ボタン */}
          <button
            onClick={() => handleStartGame()}
            className='metallic-button px-12 py-4 rounded-lg text-demon-black font-bold text-xl tracking-wide transition-all duration-300'
          >
            契約を結ぶ
          </button>
        </div>
      </div>
    );
  }

  // ゲーム画面
  return (
    <div className='min-h-screen flex flex-col p-4 md:p-8'>
      {/* ヘッダー */}
      <header className='flex justify-between items-center mb-6'>
        <div className='flex items-center gap-4'>
          <h1 className='text-2xl md:text-3xl font-bold text-demon-gold'>悪魔的しりとり</h1>
          {session && (
            <div className='flex items-center gap-2'>
              <span className='text-demon-parchment/60 text-sm'>
                Lv.{session.aiLevel}
              </span>
              <span className='text-demon-parchment/40'>|</span>
              <span className={`text-sm font-bold ${session.isOvertime ? 'text-red-400 animate-pulse' : 'text-demon-gold'}`}>
                {session.isOvertime ? '延長戦' : `Round ${session.roundCount}/${session.maxRounds}`}
              </span>
            </div>
          )}
        </div>
        <div className='flex items-center gap-4'>
          {/* タイマー */}
          {phase === 'playing' && !isAiThinking && (
            <div className={`font-mono text-2xl font-bold ${getTimeColor()}`}>
              {formatTime(remainingTime)}
            </div>
          )}
          {isAiThinking && (
            <div className='text-demon-gold text-sm animate-pulse'>
              悪魔が思考中...
            </div>
          )}
          <button
            onClick={() => {
              setPhase('title');
              setSession(null);
            }}
            className='text-demon-parchment/60 hover:text-demon-gold transition-colors text-sm'
          >
            契約破棄
          </button>
        </div>
      </header>

      <div className='flex-1 flex flex-col lg:flex-row gap-6'>
        {/* メインゲームエリア */}
        <div className='flex-1 flex flex-col'>
          {/* 悪魔のメッセージ */}
          <div className='demon-message rounded-lg p-6 mb-6'>
            <div className='flex items-start gap-4'>
              <div className='w-12 h-12 flex-shrink-0'>
                <svg viewBox='0 0 100 100' className='w-full h-full'>
                  <ellipse cx='35' cy='45' rx='8' ry='5' fill='#3D0000' />
                  <ellipse cx='65' cy='45' rx='8' ry='5' fill='#3D0000' />
                  <circle cx='35' cy='45' r='3' fill='#D4AF37' className='animate-flicker' />
                  <circle cx='65' cy='45' r='3' fill='#D4AF37' className='animate-flicker' />
                  <path d='M25 30 L30 45 L20 42 Z' fill='#3D0000' />
                  <path d='M75 30 L70 45 L80 42 Z' fill='#3D0000' />
                  <path d='M35 65 Q50 75 65 65' fill='none' stroke='#D4AF37' strokeWidth='2' />
                </svg>
              </div>
              <div className='flex-1'>
                <p className='text-demon-parchment text-lg italic'>「{demonMessage}」</p>
                {lastAiResult?.isValid && lastAiResult.word && (
                  <p className='text-demon-gold text-3xl font-bold mt-3 animate-pulse-glow'>
                    {lastAiResult.word}
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* 次の頭文字表示 */}
          {session?.expectedStartChar && phase === 'playing' && (
            <div className='text-center mb-6'>
              <span className='text-demon-parchment/60'>次の頭文字: </span>
              <span className='text-demon-gold text-4xl font-bold animate-pulse-glow'>
                「{session.expectedStartChar}」
              </span>
            </div>
          )}

          {/* 入力フォーム */}
          {phase === 'playing' && (
            <form onSubmit={handleSubmitWord} className='mb-6'>
              <div className={`flex gap-4 ${isShaking ? 'animate-shake' : ''}`}>
                <input
                  ref={inputRef}
                  type='text'
                  value={inputWord}
                  onChange={handleInputChange}
                  placeholder='ひらがなで入力せよ...'
                  className='demon-input flex-1 px-6 py-4 rounded-lg text-xl'
                  disabled={isSubmitting || isAiThinking}
                />
                <button
                  type='submit'
                  disabled={isSubmitting || isAiThinking || !inputWord.trim()}
                  className='metallic-button px-8 py-4 rounded-lg text-demon-black font-bold disabled:opacity-50 disabled:cursor-not-allowed transition-all'
                >
                  {isSubmitting || isAiThinking ? '...' : '送信'}
                </button>
              </div>
              {lastPlayerResult && !lastPlayerResult.isValid && (
                <p className='text-red-400 mt-2 text-sm'>
                  ⚠ お手つき！ ({session?.playerMistakeCount}/2)
                </p>
              )}
            </form>
          )}

          {/* ゲームオーバー画面 */}
          {phase === 'game_over' && (
            <div className='text-center py-8'>
              <h2 className={`text-4xl font-bold mb-4 ${winner === 'player' ? 'text-demon-gold' : 'text-red-500'}`}>
                {winner === 'player' ? '汝の勝利' : '悪魔の勝利'}
              </h2>
              <p className='text-demon-parchment/80 mb-8 text-lg italic'>
                「{demonMessage}」
              </p>
              
              {/* レベル選択で再戦 */}
              <div className='demon-message rounded-lg p-6 mb-6 max-w-md mx-auto'>
                <h3 className='text-demon-gold font-bold text-lg mb-4'>再戦を挑むか？</h3>
                <div className='flex gap-4 justify-center'>
                  {([1, 2, 3] as AiLevel[]).map((level) => (
                    <button
                      key={level}
                      onClick={() => handleStartGame(level)}
                      className='metallic-button px-6 py-3 rounded-lg text-demon-black font-bold transition-all'
                    >
                      <div className='text-lg'>Lv.{level}</div>
                      <div className='text-xs opacity-80'>{getLevelName(level)}</div>
                    </button>
                  ))}
                </div>
              </div>
              
              <button
                onClick={() => {
                  setPhase('title');
                  setSession(null);
                }}
                className='text-demon-parchment/60 hover:text-demon-gold transition-colors text-sm'
              >
                タイトルに戻る
              </button>
            </div>
          )}

          {/* 履歴 */}
          <div
            ref={historyRef}
            className='flex-1 gothic-border rounded-lg p-4 overflow-y-auto max-h-[300px] bg-demon-shadow/50'
          >
            <h3 className='text-demon-gold font-bold mb-3 text-sm'>言霊の記録</h3>
            <div className='space-y-2'>
              {session?.history.map((entry, index) => (
                <div
                  key={index}
                  className={`flex items-center gap-3 text-sm ${
                    entry.player === 'ai' ? 'justify-start' : 'justify-end'
                  }`}
                >
                  <div
                    className={`px-4 py-2 rounded-lg ${
                      entry.player === 'ai'
                        ? 'bg-demon-crimson/50 text-demon-parchment'
                        : entry.isValid
                          ? 'bg-demon-gold/20 text-demon-gold'
                          : 'bg-red-900/50 text-red-400'
                    }`}
                  >
                    <span className='font-bold'>{entry.word || '(敗北)'}</span>
                    {entry.capturedChars.length > 0 && (
                      <span className='ml-2 text-xs opacity-70'>
                        +{entry.capturedChars.join(', ')}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* サイドバー: 確保文字 */}
        <aside className='lg:w-64 gothic-border rounded-lg p-4 bg-demon-shadow/50'>
          <h3 className='text-demon-gold font-bold mb-4'>確保された文字</h3>
          
          {/* プレイヤーの確保文字 */}
          <div className='mb-6'>
            <div className='flex justify-between items-center mb-2'>
              <h4 className='text-demon-parchment/60 text-sm'>汝の領域</h4>
              <span className='text-demon-gold font-bold'>{session?.playerCapturedChars.length ?? 0}文字</span>
            </div>
            <div className='flex flex-wrap gap-2'>
              {session?.playerCapturedChars.length ? (
                session.playerCapturedChars.map((char) => (
                  <span
                    key={char}
                    className='w-8 h-8 flex items-center justify-center bg-demon-gold/20 text-demon-gold rounded border border-demon-gold/50 text-lg font-bold'
                  >
                    {char}
                  </span>
                ))
              ) : (
                <span className='text-demon-parchment/40 text-sm'>なし</span>
              )}
            </div>
          </div>

          {/* AIの確保文字 */}
          <div className='mb-6'>
            <div className='flex justify-between items-center mb-2'>
              <h4 className='text-demon-parchment/60 text-sm'>悪魔の領域</h4>
              <span className='text-red-400 font-bold'>{session?.aiCapturedChars.length ?? 0}文字</span>
            </div>
            <div className='flex flex-wrap gap-2'>
              {session?.aiCapturedChars.length ? (
                session.aiCapturedChars.map((char) => (
                  <span
                    key={char}
                    className='w-8 h-8 flex items-center justify-center bg-demon-crimson/50 text-red-400 rounded border border-red-500/50 text-lg font-bold'
                  >
                    {char}
                  </span>
                ))
              ) : (
                <span className='text-demon-parchment/40 text-sm'>なし</span>
              )}
            </div>
          </div>

          {/* お手つきカウント */}
          <div className='border-t border-demon-gold/20 pt-4'>
            <h4 className='text-demon-parchment/60 text-sm mb-2'>お手つき</h4>
            <div className='flex justify-between'>
              <div>
                <span className='text-demon-parchment/60 text-xs'>汝: </span>
                <span className={`font-bold ${(session?.playerMistakeCount ?? 0) > 0 ? 'text-red-400' : 'text-demon-parchment'}`}>
                  {session?.playerMistakeCount ?? 0}/2
                </span>
              </div>
              <div>
                <span className='text-demon-parchment/60 text-xs'>悪魔: </span>
                <span className={`font-bold ${(session?.aiMistakeCount ?? 0) > 0 ? 'text-demon-gold' : 'text-demon-parchment'}`}>
                  {session?.aiMistakeCount ?? 0}/2
                </span>
              </div>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
