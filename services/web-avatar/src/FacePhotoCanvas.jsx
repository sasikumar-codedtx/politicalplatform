import React, { useEffect, useRef, useState } from 'react'
import { detectFaceBoxes } from './faceLandmarks.js'

/**
 * Realtime 2D talking-head animation rendered on a <canvas>.
 *
 * - Photo is drawn every frame with a subtle head sway.
 * - Audio amplitude (from SentenceAudioPlayer.AnalyserNode) drives a tapered
 *   dark shape inside the actual mouth bbox detected by MediaPipe.
 * - If face detection fails or the model can't load, falls back to centered
 *   fraction heuristics so the avatar still animates.
 *
 * The blink overlay that used to live here was removed — without proper
 * eyelid warping it looked like a censor bar. MVP3 can re-add it by
 * compositing skin-toned pixels sampled from the brow with a curved mask.
 */
const FALLBACK_MOUTH = { cx: 0.50, cy: 0.70, w: 0.22, h: 0.08 }
const MOUTH_INTERIOR = '#23110d'

export default function FacePhotoCanvas({ photoUrl, player }) {
  const canvasRef = useRef(null)
  const imgRef    = useRef(null)
  const [mouthBox, setMouthBox] = useState(FALLBACK_MOUTH)
  const [detectStatus, setDetectStatus] = useState('pending')   // pending | ok | fallback

  const stateRef = useRef({
    smoothedAmp: 0,
    sway: { angle: 0, target: 0, next: 1 },
  })

  // Load the photo and detect landmarks. Canvas internal size matches photo
  // natural dimensions so bbox fractions map cleanly; CSS scales the display.
  useEffect(() => {
    let cancelled = false
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.src = photoUrl
    img.onload = async () => {
      if (cancelled) return
      imgRef.current = img
      const c = canvasRef.current
      if (c) {
        c.width  = img.naturalWidth
        c.height = img.naturalHeight
      }
      try {
        const boxes = await detectFaceBoxes(img)
        if (cancelled) return
        if (boxes && boxes.mouth.w > 0 && boxes.mouth.h > 0) {
          setMouthBox(boxes.mouth)
          setDetectStatus('ok')
        } else {
          setMouthBox(FALLBACK_MOUTH)
          setDetectStatus('fallback')
        }
      } catch (_) {
        if (!cancelled) {
          setMouthBox(FALLBACK_MOUTH)
          setDetectStatus('fallback')
        }
      }
    }
    return () => { cancelled = true; imgRef.current = null }
  }, [photoUrl])

  // Single rAF loop — photo + sway + mouth amplitude.
  useEffect(() => {
    let raf = 0
    let last = performance.now()

    const tick = () => {
      const canvas = canvasRef.current
      const img    = imgRef.current
      const s      = stateRef.current
      if (!canvas || !img) { raf = requestAnimationFrame(tick); return }

      const now = performance.now()
      const dt  = Math.min(0.05, (now - last) / 1000)
      last = now

      const raw    = player.amplitude()
      const target = Math.min(1, raw * 5)
      s.smoothedAmp += (target - s.smoothedAmp) * 0.42
      const amp = s.smoothedAmp

      s.sway.next -= dt
      if (s.sway.next < 0) {
        s.sway.target = (Math.random() - 0.5) * 0.04
        s.sway.next   = 2.5 + Math.random() * 2
      }
      s.sway.angle += (s.sway.target - s.sway.angle) * 0.04

      const ctx = canvas.getContext('2d')
      const W = canvas.width
      const H = canvas.height

      ctx.clearRect(0, 0, W, H)
      ctx.save()
      ctx.translate(W / 2, H / 2 + amp * 4)
      ctx.rotate(s.sway.angle)
      ctx.translate(-W / 2, -H / 2)

      ctx.drawImage(img, 0, 0, W, H)

      // Mouth — dark tapered shape inside the detected mouth bbox.
      // Width matches the mouth; height grows with amplitude. We draw at
      // ~60% of the bbox width and 100% of the bbox height so the dark
      // doesn't leak outside the lips when amplitude is high.
      if (amp > 0.04 && mouthBox.w > 0 && mouthBox.h > 0) {
        const cx = mouthBox.cx * W
        const cy = mouthBox.cy * H + amp * mouthBox.h * H * 0.15
        const rx = mouthBox.w * W * 0.30
        const ry = mouthBox.h * H * (0.18 + amp * 1.0)
        ctx.fillStyle = MOUTH_INTERIOR
        ctx.beginPath()
        ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2)
        ctx.fill()
      }

      ctx.restore()
      raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [player, mouthBox])

  return (
    <div className="face-canvas-stage">
      <canvas ref={canvasRef} />
      {detectStatus === 'fallback' && (
        <div className="face-warning">
          Face not detected — using fallback mouth position. Try a clearer
          forward-facing portrait, or tune <code>FALLBACK_MOUTH</code> in
          <code> FacePhotoCanvas.jsx</code>.
        </div>
      )}
    </div>
  )
}
