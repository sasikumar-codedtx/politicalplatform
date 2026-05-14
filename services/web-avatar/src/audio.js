/**
 * Sentence-level streaming audio queue with shared AnalyserNode.
 *
 * One <audio> element is created and wired to a Web Audio AnalyserNode once.
 * `enqueue(blob)` adds an MP3 sentence; blobs play back-to-back. `amplitude()`
 * returns the current RMS level (0..1), used by the avatar to animate the
 * mouth in real time.
 */
export class SentenceAudioPlayer {
  constructor() {
    this.audioEl = new Audio()
    this.audioEl.crossOrigin = 'anonymous'
    this.audioEl.preload = 'auto'
    this.queue = []
    this.playing = false
    this.ctx = null
    this.analyser = null
    this._timeData = null
    this.onStateChange = null
  }

  _ensureContext() {
    if (this.ctx) return
    const Ctx = window.AudioContext || window.webkitAudioContext
    this.ctx = new Ctx()
    const source = this.ctx.createMediaElementSource(this.audioEl)
    this.analyser = this.ctx.createAnalyser()
    this.analyser.fftSize = 1024
    this.analyser.smoothingTimeConstant = 0.25
    this._timeData = new Uint8Array(this.analyser.fftSize)
    source.connect(this.analyser)
    this.analyser.connect(this.ctx.destination)
  }

  /** Must be called from a user-gesture handler (button click) on first use. */
  async unlock() {
    this._ensureContext()
    if (this.ctx.state === 'suspended') {
      await this.ctx.resume()
    }
  }

  enqueue(blob) {
    this.queue.push(blob)
    if (!this.playing) this._playNext()
  }

  _playNext() {
    if (this.queue.length === 0) {
      this.playing = false
      this._emit('idle')
      return
    }
    this.playing = true
    const blob = this.queue.shift()
    const url = URL.createObjectURL(blob)
    this.audioEl.src = url
    this.audioEl.onended = () => {
      URL.revokeObjectURL(url)
      this._playNext()
    }
    this.audioEl.onerror = () => {
      URL.revokeObjectURL(url)
      this._playNext()
    }
    const p = this.audioEl.play()
    if (p && p.catch) p.catch(() => { /* autoplay blocked — ignore */ })
    this._emit('speaking')
  }

  amplitude() {
    if (!this.analyser) return 0
    this.analyser.getByteTimeDomainData(this._timeData)
    let sum = 0
    for (let i = 0; i < this._timeData.length; i++) {
      const v = (this._timeData[i] - 128) / 128
      sum += v * v
    }
    return Math.sqrt(sum / this._timeData.length)
  }

  reset() {
    this.queue = []
    try { this.audioEl.pause() } catch (_) {}
    this.audioEl.removeAttribute('src')
    this.playing = false
    this._emit('idle')
  }

  _emit(state) {
    if (this.onStateChange) this.onStateChange(state)
  }
}
