import { useEffect, useMemo, useRef, useState, useCallback } from 'react'
import { SentenceAudioPlayer } from './audio.js'

/**
 * WebSocket-driven avatar chat hook.
 *
 * Lifecycle: connect once, send one user_message per turn. The server streams
 * back token frames (live caption), audio envelopes (MP3 per sentence) and
 * finally a done frame. Audio plays sequentially through SentenceAudioPlayer;
 * the AvatarCanvas reads `player.amplitude()` for lip sync.
 */
export function useAvatarChat({ wsUrl, sessionId, flavorId, token, avatarId, onSentence, muteLocalAudio }) {
  const [messages, setMessages] = useState([])
  const [streaming, setStreaming] = useState(false)
  const [caption, setCaption] = useState('')
  const [status, setStatus] = useState('idle')   // idle | connecting | ready | speaking | error
  const [error, setError] = useState(null)

  const wsRef = useRef(null)
  const pendingEnvelopeRef = useRef(null)
  const assistantBufRef = useRef('')

  const player = useMemo(() => {
    const p = new SentenceAudioPlayer()
    p.onStateChange = (s) => {
      setStatus(prev => (s === 'speaking' ? 'speaking' : (prev === 'speaking' ? 'ready' : prev)))
    }
    return p
  }, [])

  const ensureSocket = useCallback(() => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) return wsRef.current
    setStatus('connecting')
    const ws = new WebSocket(wsUrl)
    ws.binaryType = 'arraybuffer'
    ws.onopen = () => setStatus('ready')
    ws.onerror = () => { setStatus('error'); setError('WebSocket error') }
    ws.onclose = () => { setStatus(prev => prev === 'error' ? 'error' : 'idle') }
    ws.onmessage = (ev) => handleMessage(ev)
    wsRef.current = ws
    return ws
  }, [wsUrl])

  const handleMessage = useCallback((ev) => {
    if (typeof ev.data === 'string') {
      const msg = JSON.parse(ev.data)
      if (msg.type === 'token') {
        assistantBufRef.current += msg.text
        setCaption(assistantBufRef.current)
        setMessages(prev => updateLastAssistant(prev, assistantBufRef.current, true))
      } else if (msg.type === 'sentence') {
        if (onSentence) onSentence(msg.text)
      } else if (msg.type === 'audio') {
        pendingEnvelopeRef.current = msg
      } else if (msg.type === 'done') {
        const final = msg.reply || assistantBufRef.current
        setMessages(prev => updateLastAssistant(prev, final, false))
        assistantBufRef.current = ''
        setStreaming(false)
      } else if (msg.type === 'error') {
        setError(msg.detail || 'Server error')
        setStatus('error')
        setStreaming(false)
      }
    } else {
      const env = pendingEnvelopeRef.current
      pendingEnvelopeRef.current = null
      if (!env || muteLocalAudio) return
      const blob = new Blob([ev.data], { type: env.mime || 'audio/mpeg' })
      player.enqueue(blob)
    }
  }, [player, onSentence, muteLocalAudio])

  const send = useCallback(async (text) => {
    const trimmed = text.trim()
    if (!trimmed) return
    setError(null)
    await player.unlock()

    setMessages(prev => [
      ...prev,
      { role: 'user', text: trimmed },
      { role: 'ai',   text: '', streaming: true },
    ])
    assistantBufRef.current = ''
    setCaption('')
    setStreaming(true)

    const ws = ensureSocket()
    const payload = {
      type: 'user_message',
      session_id: sessionId,
      message: trimmed,
      flavor_id: flavorId,
      avatar_id: avatarId || null,
      token,
    }
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(payload))
    } else {
      ws.addEventListener('open', () => ws.send(JSON.stringify(payload)), { once: true })
    }
  }, [ensureSocket, sessionId, flavorId, token, avatarId, player])

  useEffect(() => () => {
    if (wsRef.current) wsRef.current.close()
    player.reset()
  }, [player])

  return { messages, streaming, caption, status, error, send, player }
}

function updateLastAssistant(list, text, streaming) {
  if (list.length === 0) return list
  const copy = list.slice()
  for (let i = copy.length - 1; i >= 0; i--) {
    if (copy[i].role === 'ai') {
      copy[i] = { ...copy[i], text, streaming }
      break
    }
  }
  return copy
}
