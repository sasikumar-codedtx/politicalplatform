import React, { useEffect, useMemo, useRef, useState } from 'react'
import FacePhotoCanvas from './FacePhotoCanvas.jsx'
import { useAvatarChat } from './useAvatarChat.js'

// Single gateway origin — port 9000 boots both agent (8001) and
// avatar-service (8002) and reverse-proxies them. The browser only
// ever needs this one origin.
const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:9000'
const WS_URL   = import.meta.env.VITE_WS_URL   || 'ws://localhost:9000/ws/chat'
const DEFAULT_FLAVOR = 'tn-tvk'

export default function App() {
  const [avatars, setAvatars] = useState([])
  const [avatarId, setAvatarId] = useState('')
  const [flavorId, setFlavorId] = useState(DEFAULT_FLAVOR)
  const [input, setInput] = useState('')

  const sessionId = useMemo(() => `web-${crypto.randomUUID()}`, [])

  useEffect(() => {
    fetch(`${API_BASE}/admin/avatars`)
      .then(r => r.json())
      .then(d => {
        const faceAvatars = (d.avatars || []).filter(a => a.face_avatar_id)
        setAvatars(faceAvatars)
        if (faceAvatars.length && !avatarId) setAvatarId(faceAvatars[0].id)
      })
      .catch(() => {})
  }, [])

  const selectedAvatar = avatars.find(a => a.id === avatarId) || null
  const facePhotoUrl = selectedAvatar?.face_avatar_id
    ? `${API_BASE}/avatar-svc/${selectedAvatar.face_avatar_id}/photo`
    : null

  const { messages, streaming, status, error, send, player } = useAvatarChat({
    wsUrl: WS_URL,
    sessionId,
    flavorId,
    token: 'dev',
    avatarId: avatarId || null,
  })

  const transcriptRef = useRef(null)
  useEffect(() => {
    if (transcriptRef.current) {
      transcriptRef.current.scrollTop = transcriptRef.current.scrollHeight
    }
  }, [messages])

  const lastAi = [...messages].reverse().find(m => m.role === 'ai')
  const captionText = lastAi?.text || ''

  function onSubmit(e) {
    e.preventDefault()
    if (!input.trim() || streaming) return
    send(input)
    setInput('')
  }

  const statusLabel = {
    idle:       'Ready',
    connecting: 'Connecting…',
    ready:      'Connected',
    speaking:   'Speaking',
    error:      error || 'Error',
  }[status] || 'Ready'

  return (
    <div className="app">
      <div className="stage">
        {facePhotoUrl
          ? <FacePhotoCanvas photoUrl={facePhotoUrl} player={player} />
          : (
            <div className="loading">
              <div className="spinner" />
              <span>No face avatar yet — upload one in the admin UI.</span>
            </div>
          )}

        <div className="stage-status">
          <span className={`status-dot ${status === 'speaking' ? 'speaking' : status === 'ready' ? 'ok' : status === 'error' ? 'error' : ''}`} />
          {statusLabel}
        </div>

        <div className={`caption ${captionText ? 'show' : ''}`}>
          {captionText || ' '}
        </div>
      </div>

      <aside className="panel">
        <div className="panel-header">
          <h1>Realtime Avatar</h1>
          <p>Streaming chat with 2D talking-photo animation.</p>
        </div>

        <div className="panel-section">
          <label>Avatar</label>
          <select value={avatarId} onChange={e => setAvatarId(e.target.value)}>
            {avatars.length === 0 && <option value="">— no avatars yet —</option>}
            {avatars.map(a => (
              <option key={a.id} value={a.id}>{a.name || a.id.slice(0, 8)}</option>
            ))}
          </select>
        </div>

        <div className="panel-section">
          <label>Flavor</label>
          <select value={flavorId} onChange={e => setFlavorId(e.target.value)}>
            <option value="tn-tvk">TVK</option>
            <option value="india-pm">India PM</option>
          </select>
        </div>

        <div ref={transcriptRef} className="transcript">
          {messages.length === 0 && (
            <div style={{ color: 'var(--muted)', fontSize: 13, textAlign: 'center', marginTop: 24 }}>
              Say hello to start the conversation.
            </div>
          )}
          {messages.map((m, i) => (
            <div key={i} className={`msg ${m.role} ${m.streaming ? 'streaming' : ''}`}>
              {m.text || (m.streaming ? '…' : '')}
            </div>
          ))}
        </div>

        <form className="composer" onSubmit={onSubmit}>
          <input
            value={input}
            onChange={e => setInput(e.target.value)}
            placeholder="Type your message…"
            disabled={streaming}
            autoFocus
          />
          <button type="submit" disabled={streaming || !input.trim()}>
            {streaming ? '…' : 'Send'}
          </button>
        </form>
      </aside>
    </div>
  )
}
