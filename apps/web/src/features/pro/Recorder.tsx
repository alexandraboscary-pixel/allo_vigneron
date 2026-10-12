import { useEffect, useRef, useState } from 'react'
import type { MediaKind } from '../../lib/types'
import ui from './pro.module.css'

export const MIN_S = 15
export const MAX_S = 90

const MIME = {
  video: ['video/mp4;codecs=avc1,mp4a', 'video/mp4', 'video/webm;codecs=vp9,opus', 'video/webm'],
  audio: ['audio/mp4', 'audio/webm;codecs=opus', 'audio/webm'],
}

function pickMime(kind: MediaKind) {
  return MIME[kind].find((m) => MediaRecorder.isTypeSupported(m)) ?? ''
}

export interface Take {
  blob: Blob
  kind: MediaKind
  duration: number
}

// Enregistre un audio ou une vidéo (portrait) dans le navigateur, 90 s maximum, avec réécoute.
export function Recorder({ kind, onTake }: { kind: MediaKind; onTake: (take: Take | null) => void }) {
  const [phase, setPhase] = useState<'idle' | 'live' | 'recording' | 'done'>('idle')
  const [seconds, setSeconds] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [url, setUrl] = useState<string | null>(null)
  const stream = useRef<MediaStream | null>(null)
  const recorder = useRef<MediaRecorder | null>(null)
  const chunks = useRef<Blob[]>([])
  const started = useRef(0)
  const timer = useRef<number>()
  const live = useRef<HTMLVideoElement>(null)

  function stopStream() {
    stream.current?.getTracks().forEach((t) => t.stop())
    stream.current = null
  }

  useEffect(() => () => {
    window.clearInterval(timer.current)
    stopStream()
  }, [])

  useEffect(() => () => { if (url) URL.revokeObjectURL(url) }, [url])

  async function open() {
    setError(null)
    try {
      stream.current = await navigator.mediaDevices.getUserMedia(
        kind === 'video'
          ? { audio: true, video: { facingMode: 'user', width: { ideal: 720 }, height: { ideal: 1280 } } }
          : { audio: true },
      )
      setPhase('live')
      if (kind === 'video' && live.current) {
        live.current.srcObject = stream.current
        await live.current.play().catch(() => {})
      }
    } catch {
      setError(kind === 'video'
        ? "On n'a pas accès à ta caméra. Autorise-la dans ton navigateur, puis réessaie."
        : "On n'a pas accès à ton micro. Autorise-le dans ton navigateur, puis réessaie.")
    }
  }

  function start() {
    if (!stream.current) return
    const mimeType = pickMime(kind)
    const rec = new MediaRecorder(stream.current, {
      mimeType: mimeType || undefined,
      audioBitsPerSecond: 96_000,
      videoBitsPerSecond: kind === 'video' ? 1_500_000 : undefined,
    })
    chunks.current = []
    rec.ondataavailable = (e) => e.data.size && chunks.current.push(e.data)
    rec.onstop = () => {
      const duration = Math.round((Date.now() - started.current) / 1000)
      const blob = new Blob(chunks.current, { type: rec.mimeType || mimeType || `${kind}/webm` })
      stopStream()
      setUrl(URL.createObjectURL(blob))
      setPhase('done')
      onTake({ blob, kind, duration })
    }
    recorder.current = rec
    started.current = Date.now()
    setSeconds(0)
    rec.start(1000)
    setPhase('recording')
    timer.current = window.setInterval(() => {
      const s = Math.floor((Date.now() - started.current) / 1000)
      setSeconds(s)
      if (s >= MAX_S) stop()
    }, 250)
  }

  function stop() {
    window.clearInterval(timer.current)
    if (recorder.current?.state === 'recording') recorder.current.stop()
  }

  function retry() {
    setUrl(null)
    onTake(null)
    setPhase('idle')
    setSeconds(0)
  }

  const left = MAX_S - seconds
  return (
    <div className={ui.recorder} data-kind={kind}>
      {kind === 'video' && phase !== 'done' && (
        <video ref={live} className={ui.preview} muted playsInline hidden={phase === 'idle'} />
      )}
      {phase === 'done' && url && (kind === 'video'
        ? <video src={url} className={ui.preview} controls playsInline />
        : <audio src={url} controls className={ui.audio} />)}

      {phase === 'idle' && (
        <button type="button" className={ui.recButton} onClick={open}>
          {kind === 'video' ? 'Allumer la caméra' : 'Allumer le micro'}
        </button>
      )}
      {phase === 'live' && (
        <button type="button" className={ui.recButton} onClick={start}>
          <span className={ui.recDot} /> Commencer
        </button>
      )}
      {phase === 'recording' && (
        <>
          <p className={ui.timer}>{seconds} s <small>· encore {left} s max</small></p>
          <button type="button" className={`${ui.recButton} ${ui.recording}`} onClick={stop} disabled={seconds < 3}>
            <span className={ui.recSquare} /> {seconds < MIN_S ? `Encore ${MIN_S - seconds} s minimum` : "J'ai fini"}
          </button>
        </>
      )}
      {phase === 'done' && (
        <button type="button" className={ui.secondary} onClick={retry}>Recommencer</button>
      )}
      {error && <p className={ui.error}>{error}</p>}
    </div>
  )
}
