import { useState, useEffect, useRef } from 'react'

const API = 'http://localhost:9000'
const FLAVORS = [
  { id: 'tn-tvk', label: 'TVK', color: '#E40101' },
  { id: 'india-pm', label: 'India PM', color: '#19AAED' },
]

// ── Global styles ─────────────────────────────────────────────────────────
const GLOBAL_CSS = `
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Inter', -apple-system, sans-serif; background: #F8FAFC; color: #0F172A; }
  input, textarea, select, button { font-family: inherit; }
  a { color: inherit; text-decoration: none; }
  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { background: #F1F5F9; }
  ::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 3px; }
  input:focus, textarea:focus { outline: 2px solid #6366F1; outline-offset: 0; border-color: #6366F1 !important; }
  .hover-row:hover { background: #F8FAFC !important; }
  .nav-item { transition: background 0.15s, color 0.15s; }
  .nav-item:hover { background: rgba(255,255,255,0.08) !important; }
  .btn-hover:hover { opacity: 0.88; }
  .source-link:hover { text-decoration: underline; }
  .modal-backdrop { animation: fadeIn 0.15s ease; }
  .modal-card { animation: slideUp 0.18s ease; }
  @keyframes fadeIn { from { opacity: 0 } to { opacity: 1 } }
  @keyframes slideUp { from { opacity: 0; transform: translateY(16px) } to { opacity: 1; transform: translateY(0) } }
  .tab-btn { transition: all 0.15s; }
  .tab-btn:hover { background: #F1F5F9 !important; }
  .fab-btn { transition: all 0.2s; box-shadow: 0 4px 14px rgba(99,102,241,0.35); }
  .fab-btn:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(99,102,241,0.45); }
`

function GlobalStyle() {
  useEffect(() => {
    const el = document.createElement('style')
    el.innerHTML = GLOBAL_CSS
    document.head.appendChild(el)
    return () => el.remove()
  }, [])
  return null
}

// ── Design tokens ─────────────────────────────────────────────────────────
const t = {
  sidebar: '#0F172A',
  sidebarBorder: 'rgba(255,255,255,0.07)',
  sidebarText: '#94A3B8',
  sidebarActive: 'rgba(99,102,241,0.18)',
  primary: '#6366F1',
  surface: '#FFFFFF',
  border: '#E2E8F0',
  muted: '#64748B',
  danger: '#EF4444',
  success: '#22C55E',
  warning: '#F59E0B',
  info: '#3B82F6',
}

// ── Reusable components ───────────────────────────────────────────────────

function Badge({ children, color = t.primary }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '2px 10px', borderRadius: 20, fontSize: 11, fontWeight: 600,
      background: color + '18', color,
    }}>{children}</span>
  )
}

function Button({ children, onClick, color = t.primary, variant = 'solid', size = 'md', disabled = false, type = 'button', fullWidth = false }) {
  const pad = size === 'sm' ? '5px 12px' : size === 'lg' ? '10px 24px' : '8px 18px'
  const fs = size === 'sm' ? 12 : 13
  const base = {
    padding: pad, borderRadius: 8, fontSize: fs, fontWeight: 600,
    cursor: disabled ? 'not-allowed' : 'pointer', border: 'none',
    transition: 'all 0.15s', display: 'inline-flex', alignItems: 'center', gap: 6,
    width: fullWidth ? '100%' : undefined, justifyContent: fullWidth ? 'center' : undefined,
    opacity: disabled ? 0.5 : 1,
  }
  if (variant === 'solid') return <button type={type} onClick={onClick} disabled={disabled} className="btn-hover" style={{ ...base, background: color, color: '#fff' }}>{children}</button>
  if (variant === 'outline') return <button type={type} onClick={onClick} disabled={disabled} className="btn-hover" style={{ ...base, background: 'transparent', color, border: `1.5px solid ${color}` }}>{children}</button>
  if (variant === 'ghost') return <button type={type} onClick={onClick} disabled={disabled} className="btn-hover" style={{ ...base, background: color + '12', color }}>{children}</button>
}

function Input({ label, value, onChange, placeholder, type = 'text', required, hint }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && <label style={{ fontSize: 12, fontWeight: 600, color: t.muted }}>{label}{required && <span style={{ color: t.danger }}> *</span>}</label>}
      <input value={value} onChange={onChange} placeholder={placeholder} type={type} required={required}
        style={{ padding: '9px 12px', border: `1.5px solid ${t.border}`, borderRadius: 8, fontSize: 13, color: t.sidebar, background: '#fff', width: '100%' }} />
      {hint && <span style={{ fontSize: 11, color: t.muted }}>{hint}</span>}
    </div>
  )
}

function Textarea({ label, value, onChange, placeholder, rows = 5, required }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && <label style={{ fontSize: 12, fontWeight: 600, color: t.muted }}>{label}{required && <span style={{ color: t.danger }}> *</span>}</label>}
      <textarea value={value} onChange={onChange} placeholder={placeholder} rows={rows} required={required}
        style={{ padding: '9px 12px', border: `1.5px solid ${t.border}`, borderRadius: 8, fontSize: 13, color: t.sidebar, background: '#fff', width: '100%', resize: 'vertical', lineHeight: 1.6 }} />
    </div>
  )
}

function Toast({ msg }) {
  if (!msg) return null
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderRadius: 8, marginTop: 4,
      fontSize: 13, fontWeight: 500,
      background: msg.ok ? '#F0FDF4' : '#FEF2F2',
      border: `1px solid ${msg.ok ? '#BBF7D0' : '#FECACA'}`,
      color: msg.ok ? '#15803D' : '#B91C1C',
    }}>
      {msg.ok ? '✓' : '✕'} {msg.text}
    </div>
  )
}

function Card({ children, style }) {
  return <div style={{ background: t.surface, borderRadius: 12, border: `1px solid ${t.border}`, ...style }}>{children}</div>
}

function SectionHeader({ title, action }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 20px', borderBottom: `1px solid ${t.border}` }}>
      <h2 style={{ fontSize: 14, fontWeight: 700, color: t.sidebar }}>{title}</h2>
      {action}
    </div>
  )
}

// ── Source type ───────────────────────────────────────────────────────────
function sourceType(source) {
  if (!source) return { icon: '📝', label: 'Manual', color: '#64748B' }
  if (source.includes('youtube.com') || source.includes('youtu.be')) return { icon: '▶', label: 'YouTube', color: '#EF4444' }
  if (source.startsWith('http')) return { icon: '🌐', label: 'URL', color: '#3B82F6' }
  return { icon: '📄', label: 'File', color: '#8B5CF6' }
}

// ── Data hook ─────────────────────────────────────────────────────────────
function useDocuments(flavor) {
  const [docs, setDocs] = useState([])
  const [loading, setLoading] = useState(false)
  const load = async () => {
    setLoading(true)
    try { const r = await fetch(`${API}/admin/documents?flavor_id=${flavor}`); setDocs((await r.json()).documents || []) }
    catch { setDocs([]) } finally { setLoading(false) }
  }
  useEffect(() => { load() }, [flavor])
  return { docs, loading, reload: load }
}

// ── Stat card ─────────────────────────────────────────────────────────────
function StatCard({ label, value, icon, color }) {
  return (
    <div style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: 12, padding: '16px 20px', display: 'flex', alignItems: 'center', gap: 14 }}>
      <div style={{ width: 42, height: 42, borderRadius: 10, background: color + '15', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>{icon}</div>
      <div>
        <div style={{ fontSize: 22, fontWeight: 700, color: t.sidebar, lineHeight: 1 }}>{value}</div>
        <div style={{ fontSize: 12, color: t.muted, marginTop: 3 }}>{label}</div>
      </div>
    </div>
  )
}

// ── Add Content Forms ─────────────────────────────────────────────────────
function AddTextForm({ flavor, onAdded }) {
  const [f, setF] = useState({ title: '', content: '', source: '' })
  const [loading, setLoading] = useState(false)
  const [msg, setMsg] = useState(null)
  const set = k => e => setF(p => ({ ...p, [k]: e.target.value }))
  const submit = async e => {
    e.preventDefault()
    if (!f.title || !f.content) return
    setLoading(true); setMsg(null)
    try {
      const r = await fetch(`${API}/admin/documents`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ flavor_id: flavor, ...f }) })
      const d = await r.json()
      setMsg({ ok: true, text: `Added ${d.chunks} chunk${d.chunks > 1 ? 's' : ''} to knowledge base` })
      setF({ title: '', content: '', source: '' })
      setTimeout(onAdded, 1200)
    } catch { setMsg({ ok: false, text: 'Failed to add document.' }) }
    finally { setLoading(false) }
  }
  return (
    <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <Input label="Document Title" value={f.title} onChange={set('title')} placeholder="e.g. Clean Water Scheme Overview" required />
      <Input label="Source / Reference" value={f.source} onChange={set('source')} placeholder="e.g. TVK Manifesto 2026" />
      <Textarea label="Content" value={f.content} onChange={set('content')} placeholder="Paste policy text, scheme details, speech content…" rows={6} required />
      <Toast msg={msg} />
      <Button type="submit" color={t.primary} disabled={loading} fullWidth>{loading ? 'Embedding…' : '+ Add to Knowledge Base'}</Button>
    </form>
  )
}

function UploadFileForm({ flavor, onAdded }) {
  const [title, setTitle] = useState('')
  const [source, setSource] = useState('')
  const [file, setFile] = useState(null)
  const [loading, setLoading] = useState(false)
  const [msg, setMsg] = useState(null)
  const [drag, setDrag] = useState(false)
  const ref = useRef()
  const pick = f => { setFile(f); if (!title) setTitle(f.name.replace(/\.(pdf|txt|md)$/i, '')) }
  const submit = async e => {
    e.preventDefault()
    if (!file || !title) return
    setLoading(true); setMsg(null)
    const fd = new FormData()
    fd.append('flavor_id', flavor); fd.append('title', title)
    fd.append('source', source || file.name); fd.append('file', file)
    try {
      const r = await fetch(`${API}/admin/documents/upload`, { method: 'POST', body: fd })
      const d = await r.json()
      if (!r.ok) throw new Error(d.detail || 'Upload failed')
      setMsg({ ok: true, text: `${d.chunks} chunks extracted from ${d.filename}` })
      setFile(null); setTitle(''); setSource('')
      setTimeout(onAdded, 1200)
    } catch (err) { setMsg({ ok: false, text: err.message }) }
    finally { setLoading(false) }
  }
  return (
    <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div
        onClick={() => ref.current?.click()}
        onDragOver={e => { e.preventDefault(); setDrag(true) }}
        onDragLeave={() => setDrag(false)}
        onDrop={e => { e.preventDefault(); setDrag(false); if (e.dataTransfer.files[0]) pick(e.dataTransfer.files[0]) }}
        style={{
          border: `2px dashed ${drag ? t.primary : t.border}`, borderRadius: 10, padding: '24px 20px',
          textAlign: 'center', cursor: 'pointer', background: drag ? '#EEF2FF' : '#F8FAFC', transition: 'all 0.15s',
        }}>
        <input ref={ref} type="file" accept=".pdf,.txt,.md" style={{ display: 'none' }} onChange={e => e.target.files[0] && pick(e.target.files[0])} />
        {file ? (
          <div><div style={{ fontSize: 28, marginBottom: 6 }}>📄</div>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{file.name}</div>
            <div style={{ color: t.muted, fontSize: 11, marginTop: 2 }}>{(file.size / 1024).toFixed(1)} KB · click to change</div>
          </div>
        ) : (
          <div><div style={{ fontSize: 28, marginBottom: 8 }}>☁️</div>
            <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 4 }}>Drop file here or click to browse</div>
            <div style={{ color: t.muted, fontSize: 12 }}>PDF · TXT · Markdown</div>
          </div>
        )}
      </div>
      <Input label="Document Title" value={title} onChange={e => setTitle(e.target.value)} placeholder="Auto-filled from filename" required />
      <Input label="Source Reference" value={source} onChange={e => setSource(e.target.value)} placeholder="e.g. Official Government Report" />
      <Toast msg={msg} />
      <Button type="submit" color={t.primary} disabled={loading || !file} fullWidth>{loading ? 'Processing…' : '⬆ Upload & Embed'}</Button>
    </form>
  )
}

function ScrapeUrlForm({ flavor, onAdded }) {
  const [url, setUrl] = useState('')
  const [source, setSource] = useState('')
  const [loading, setLoading] = useState(false)
  const [msg, setMsg] = useState(null)
  const submit = async e => {
    e.preventDefault()
    if (!url) return
    setLoading(true); setMsg(null)
    try {
      const r = await fetch(`${API}/admin/ingest/url`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ flavor_id: flavor, url, source }) })
      const d = await r.json()
      if (!r.ok) throw new Error(d.detail || 'Failed')
      setMsg({ ok: true, text: `"${d.title}" → ${d.chunks} chunks added` })
      setUrl(''); setSource('')
      setTimeout(onAdded, 1200)
    } catch (err) { setMsg({ ok: false, text: err.message }) }
    finally { setLoading(false) }
  }
  return (
    <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div style={{ background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: 8, padding: '10px 14px', fontSize: 12, color: '#1E40AF', lineHeight: 1.6 }}>
        Paste any website URL — the page text will be fetched, chunked, and embedded automatically.
      </div>
      <Input label="Website URL" value={url} onChange={e => setUrl(e.target.value)} placeholder="https://tngovernment.in/scheme/..." type="url" required />
      <Input label="Custom Title (optional)" value={source} onChange={e => setSource(e.target.value)} placeholder="Leave blank to use page title" />
      <Toast msg={msg} />
      <Button type="submit" color={t.info} disabled={loading} fullWidth>{loading ? 'Scraping…' : '🌐 Scrape & Add'}</Button>
    </form>
  )
}

function YouTubeForm({ flavor, onAdded }) {
  const [url, setUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [msg, setMsg] = useState(null)
  const submit = async e => {
    e.preventDefault()
    if (!url) return
    setLoading(true); setMsg(null)
    try {
      const r = await fetch(`${API}/admin/ingest/youtube`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ flavor_id: flavor, url }) })
      const d = await r.json()
      if (!r.ok) throw new Error(d.detail || 'Failed')
      setMsg({ ok: true, text: `"${d.title}" → ${d.chunks} chunks added` })
      setUrl('')
      setTimeout(onAdded, 1200)
    } catch (err) { setMsg({ ok: false, text: err.message }) }
    finally { setLoading(false) }
  }
  return (
    <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div style={{ background: '#FFF7ED', border: '1px solid #FED7AA', borderRadius: 8, padding: '10px 14px', fontSize: 12, color: '#9A3412', lineHeight: 1.6 }}>
        Paste any YouTube video URL — speeches, interviews, press conferences. The transcript will be extracted and indexed.
      </div>
      <Input label="YouTube URL" value={url} onChange={e => setUrl(e.target.value)} placeholder="https://youtube.com/watch?v=..." type="url" required />
      <Toast msg={msg} />
      <Button type="submit" color={t.danger} disabled={loading} fullWidth>{loading ? 'Fetching transcript…' : '▶ Add YouTube Transcript'}</Button>
    </form>
  )
}

// ── Add Content Modal ─────────────────────────────────────────────────────
const ADD_TABS = [
  { id: 'text', icon: '✏️', label: 'Paste Text' },
  { id: 'file', icon: '📁', label: 'Upload File' },
  { id: 'url', icon: '🌐', label: 'Scrape URL' },
  { id: 'youtube', icon: '▶', label: 'YouTube' },
]

function AddContentModal({ flavor, onClose, onAdded }) {
  const [tab, setTab] = useState('text')

  // close on Escape
  useEffect(() => {
    const handler = e => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  const handleAdded = () => { onAdded(); onClose() }

  return (
    <div
      className="modal-backdrop"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
      style={{
        position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.55)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 1000, padding: 24,
      }}>
      <div className="modal-card" style={{
        background: '#fff', borderRadius: 16, width: '100%', maxWidth: 560,
        boxShadow: '0 20px 60px rgba(0,0,0,0.18)', overflow: 'hidden',
      }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 24px', borderBottom: `1px solid ${t.border}` }}>
          <div>
            <div style={{ fontWeight: 700, fontSize: 16, color: t.sidebar }}>Add to Knowledge Base</div>
            <div style={{ fontSize: 12, color: t.muted, marginTop: 2 }}>Choose a source type below</div>
          </div>
          <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, border: 'none', background: '#F1F5F9', cursor: 'pointer', fontSize: 16, color: t.muted, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>✕</button>
        </div>

        {/* Segment tabs */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', borderBottom: `1px solid ${t.border}` }}>
          {ADD_TABS.map(tb => (
            <button key={tb.id} onClick={() => setTab(tb.id)} className="tab-btn" style={{
              padding: '12px 8px', border: 'none', cursor: 'pointer', textAlign: 'center',
              background: tab === tb.id ? '#fff' : '#F8FAFC',
              borderBottom: tab === tb.id ? `2px solid ${t.primary}` : '2px solid transparent',
              color: tab === tb.id ? t.primary : t.muted,
              fontWeight: tab === tb.id ? 700 : 400,
              fontSize: 12, transition: 'all 0.15s',
            }}>
              <div style={{ fontSize: 18, marginBottom: 4 }}>{tb.icon}</div>
              {tb.label}
            </button>
          ))}
        </div>

        {/* Form body */}
        <div style={{ padding: 24, maxHeight: '65vh', overflowY: 'auto' }}>
          {tab === 'text' && <AddTextForm flavor={flavor} onAdded={handleAdded} />}
          {tab === 'file' && <UploadFileForm flavor={flavor} onAdded={handleAdded} />}
          {tab === 'url' && <ScrapeUrlForm flavor={flavor} onAdded={handleAdded} />}
          {tab === 'youtube' && <YouTubeForm flavor={flavor} onAdded={handleAdded} />}
        </div>
      </div>
    </div>
  )
}

// ── Documents view ────────────────────────────────────────────────────────
function DocumentsView({ flavor, docs, loading, onDelete }) {
  const [search, setSearch] = useState('')
  const filtered = docs.filter(d =>
    !search ||
    d.title.toLowerCase().includes(search.toLowerCase()) ||
    (d.source || '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <Card>
      <SectionHeader
        title={`Knowledge Base · ${docs.length} documents`}
        action={
          <div style={{ position: 'relative' }}>
            <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: t.muted, fontSize: 13 }}>🔍</span>
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search documents…"
              style={{ padding: '7px 12px 7px 30px', border: `1.5px solid ${t.border}`, borderRadius: 8, fontSize: 12, width: 200, color: t.sidebar }} />
          </div>
        }
      />
      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading documents…</div>
      ) : filtered.length === 0 ? (
        <div style={{ padding: 48, textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>📭</div>
          <div style={{ color: t.muted, fontSize: 13 }}>{search ? 'No documents match your search.' : 'No documents yet. Click "+ Add Content" to get started.'}</div>
        </div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#F8FAFC' }}>
              {['#', 'Title & Preview', 'Source', 'Type', 'Added', ''].map((h, i) => (
                <th key={i} style={{ padding: '10px 16px', textAlign: 'left', fontSize: 11, fontWeight: 600, color: t.muted, borderBottom: `1px solid ${t.border}`, whiteSpace: 'nowrap' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.map(doc => {
              const st = sourceType(doc.source)
              return (
                <tr key={doc.id} className="hover-row" style={{ borderBottom: `1px solid ${t.border}` }}>
                  <td style={{ padding: '12px 16px', color: t.muted, fontSize: 12, width: 36, fontVariantNumeric: 'tabular-nums' }}>{doc.id}</td>
                  <td style={{ padding: '12px 16px', maxWidth: 380 }}>
                    <div style={{ fontWeight: 600, fontSize: 13, color: t.sidebar, marginBottom: 3 }}>{doc.title}</div>
                    <div style={{ fontSize: 11, color: t.muted, lineHeight: 1.5, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{doc.preview}</div>
                  </td>
                  <td style={{ padding: '12px 16px', maxWidth: 180 }}>
                    {doc.source ? (
                      doc.source.startsWith('http')
                        ? <a href={doc.source} target="_blank" rel="noreferrer" className="source-link" style={{ fontSize: 11, color: t.info, display: 'block', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 160 }}>{doc.source}</a>
                        : <span style={{ fontSize: 11, color: t.muted }}>{doc.source}</span>
                    ) : <span style={{ color: t.border }}>—</span>}
                  </td>
                  <td style={{ padding: '12px 16px', whiteSpace: 'nowrap' }}>
                    <Badge color={st.color}>{st.icon} {st.label}</Badge>
                  </td>
                  <td style={{ padding: '12px 16px', fontSize: 11, color: t.muted, whiteSpace: 'nowrap' }}>
                    {new Date(doc.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: '2-digit' })}
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <Button variant="ghost" color={t.danger} size="sm" onClick={() => onDelete(doc.id)}>Delete</Button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </Card>
  )
}

// ── Test Query ────────────────────────────────────────────────────────────
function TestQueryView({ flavor }) {
  const [query, setQuery] = useState('')
  const [topK, setTopK] = useState(3)
  const [results, setResults] = useState(null)
  const [loading, setLoading] = useState(false)
  const run = async e => {
    e.preventDefault()
    if (!query) return
    setLoading(true); setResults(null)
    try {
      const r = await fetch(`${API}/admin/test-query`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ flavor_id: flavor, query, top_k: topK }) })
      setResults(await r.json())
    } finally { setLoading(false) }
  }
  return (
    <Card>
      <SectionHeader title="Test Retrieval" />
      <div style={{ padding: 20 }}>
        <form onSubmit={run} style={{ display: 'flex', gap: 10, alignItems: 'flex-end', marginBottom: 20 }}>
          <div style={{ flex: 1 }}>
            <Input label="Ask a question" value={query} onChange={e => setQuery(e.target.value)} placeholder="e.g. What is the free bus scheme for women?" />
          </div>
          <div style={{ width: 80 }}>
            <Input label="Top K" value={topK} onChange={e => setTopK(Number(e.target.value))} type="number" />
          </div>
          <Button type="submit" color={t.primary} disabled={loading}>{loading ? '…' : 'Search'}</Button>
        </form>

        {!results && !loading && (
          <div style={{ textAlign: 'center', padding: '40px 0', color: t.muted, fontSize: 13 }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>🔍</div>
            Enter a question to see which documents would be retrieved by the AI
          </div>
        )}

        {results?.message && <Toast msg={{ ok: false, text: results.message }} />}

        {results?.results?.map((r, i) => (
          <div key={i} style={{ border: `1px solid ${t.border}`, borderRadius: 10, padding: 16, marginBottom: 12 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
              <div>
                <div style={{ fontWeight: 600, fontSize: 13, color: t.sidebar }}>{r.title}</div>
                {r.source && <div style={{ fontSize: 11, color: t.muted, marginTop: 2 }}>📎 {r.source.length > 60 ? r.source.slice(0, 60) + '…' : r.source}</div>}
              </div>
              <Badge color={r.similarity > 0.7 ? t.success : r.similarity > 0.5 ? t.warning : t.muted}>
                {(r.similarity * 100).toFixed(1)}% match
              </Badge>
            </div>
            <div style={{ height: 4, borderRadius: 2, background: t.border, overflow: 'hidden', marginBottom: 10 }}>
              <div style={{ height: '100%', width: `${r.similarity * 100}%`, background: r.similarity > 0.7 ? t.success : r.similarity > 0.5 ? t.warning : t.muted, borderRadius: 2 }} />
            </div>
            <div style={{ fontSize: 12, color: t.muted, lineHeight: 1.7, background: '#F8FAFC', padding: '10px 12px', borderRadius: 8 }}>{r.preview}…</div>
          </div>
        ))}
        {results?.results?.length === 0 && (
          <div style={{ textAlign: 'center', padding: '32px 0', color: t.muted, fontSize: 13 }}>No results above the similarity threshold.</div>
        )}
      </div>
    </Card>
  )
}

// ── Audit Log ─────────────────────────────────────────────────────────────
const ACTION_META = {
  document_added: { icon: '📝', color: t.success, label: 'Added' },
  file_uploaded: { icon: '📁', color: '#8B5CF6', label: 'File' },
  url_scraped: { icon: '🌐', color: t.info, label: 'URL' },
  youtube_ingested: { icon: '▶', color: t.danger, label: 'YouTube' },
  document_deleted: { icon: '🗑', color: t.warning, label: 'Deleted' },
  session_deleted: { icon: '💬', color: t.muted, label: 'Session' },
  chat_message: { icon: '💬', color: '#94A3B8', label: 'Chat' },
  injection_blocked: { icon: '🚨', color: t.danger, label: 'Blocked' },
  url_scrape_failed: { icon: '⚠️', color: t.warning, label: 'URL Fail' },
  youtube_ingest_failed: { icon: '⚠️', color: t.warning, label: 'YT Fail' },
  prompt_updated: { icon: '🎭', color: t.primary, label: 'Prompt' },
  prompt_reset: { icon: '↺', color: t.muted, label: 'Reset' },
}

function AuditLogView() {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(false)
  const [filter, setFilter] = useState('all')
  const load = async () => {
    setLoading(true)
    try { const r = await fetch(`${API}/admin/audit-logs?limit=200`); setLogs((await r.json()).logs || []) }
    finally { setLoading(false) }
  }
  useEffect(() => { load() }, [])

  const filtered = filter === 'all' ? logs : logs.filter(l => l.action === filter || (filter === 'errors' && l.status === 'error'))
  const categories = ['all', 'document_added', 'file_uploaded', 'url_scraped', 'youtube_ingested', 'injection_blocked', 'errors']

  return (
    <Card>
      <SectionHeader title={`Audit Log · ${logs.length} events`} action={<Button variant="ghost" color={t.muted} size="sm" onClick={load}>↻ Refresh</Button>} />
      <div style={{ padding: '12px 20px', borderBottom: `1px solid ${t.border}`, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        {categories.map(cat => (
          <button key={cat} onClick={() => setFilter(cat)} style={{
            padding: '4px 12px', borderRadius: 20, fontSize: 11, fontWeight: 600,
            cursor: 'pointer', border: 'none',
            background: filter === cat ? t.sidebar : '#F1F5F9',
            color: filter === cat ? '#fff' : t.muted,
          }}>
            {ACTION_META[cat]?.icon || ''} {cat === 'all' ? `All (${logs.length})` : cat === 'errors' ? '⚠️ Errors' : ACTION_META[cat]?.label || cat}
          </button>
        ))}
      </div>
      {loading
        ? <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading…</div>
        : filtered.length === 0
          ? <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>No events yet.</div>
          : (
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: '#F8FAFC' }}>
                  {['Time', 'Action', 'Details', 'Status'].map((h, i) => (
                    <th key={i} style={{ padding: '10px 16px', textAlign: 'left', fontSize: 11, fontWeight: 600, color: t.muted, borderBottom: `1px solid ${t.border}` }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map(log => {
                  const meta = ACTION_META[log.action] || { icon: '•', color: t.muted, label: log.action }
                  return (
                    <tr key={log.id} className="hover-row" style={{ borderBottom: `1px solid ${t.border}` }}>
                      <td style={{ padding: '10px 16px', fontSize: 11, color: t.muted, whiteSpace: 'nowrap' }}>
                        {new Date(log.created_at).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                      </td>
                      <td style={{ padding: '10px 16px', whiteSpace: 'nowrap' }}>
                        <Badge color={meta.color}>{meta.icon} {meta.label}</Badge>
                      </td>
                      <td style={{ padding: '10px 16px', fontSize: 12, color: t.muted, maxWidth: 400 }}>
                        {log.metadata?.title && <span style={{ fontWeight: 600, color: t.sidebar }}>{log.metadata.title}</span>}
                        {log.metadata?.url && <span style={{ display: 'block', fontSize: 11, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 340 }}>{log.metadata.url}</span>}
                        {log.metadata?.chunks && <> <Badge color={t.primary}>{log.metadata.chunks} chunks</Badge></>}
                        {log.metadata?.message_preview && <span style={{ fontStyle: 'italic' }}>"{log.metadata.message_preview}"</span>}
                        {log.error_msg && <span style={{ color: t.danger }}> {log.error_msg}</span>}
                      </td>
                      <td style={{ padding: '10px 16px' }}>
                        <Badge color={log.status === 'success' ? t.success : t.danger}>{log.status}</Badge>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
    </Card>
  )
}

// ── Prompts view ──────────────────────────────────────────────────────────
const CATEGORY_ICON = {
  persona: '🎭',
  role_anchor: '⚓',
  language: '🌐',
  refusal: '🛡',
  rag: '📎',
  misc: '•',
}

function PromptEditor({ prompt, onSaved }) {
  const [content, setContent] = useState(prompt.content)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState(null)
  const [expanded, setExpanded] = useState(false)
  const lineCount = (content.match(/\n/g) || []).length + 1
  const isLarge = lineCount > 8 || content.length > 400

  useEffect(() => { setContent(prompt.content); setMsg(null) }, [prompt.key, prompt.content])

  const dirty = content !== prompt.content
  const encodedKey = prompt.key.split('/').map(encodeURIComponent).join('/')

  const save = async () => {
    if (!content.trim()) { setMsg({ ok: false, text: 'Cannot be empty' }); return }
    setSaving(true); setMsg(null)
    try {
      const r = await fetch(`${API}/admin/prompts/${encodedKey}`, {
        method: 'PUT', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content }),
      })
      const d = await r.json()
      if (!r.ok) throw new Error(d.detail || 'Failed to save')
      setMsg({ ok: true, text: `Saved · ${d.length} chars` })
      onSaved()
    } catch (e) { setMsg({ ok: false, text: e.message }) }
    finally { setSaving(false) }
  }

  const reset = async () => {
    if (!confirm(`Reset "${prompt.label}" to the factory default? Current edits will be overwritten.`)) return
    setSaving(true); setMsg(null)
    try {
      const r = await fetch(`${API}/admin/prompts/${encodedKey}/reset`, { method: 'POST' })
      const d = await r.json()
      if (!r.ok) throw new Error(d.detail || 'Failed to reset')
      setMsg({ ok: true, text: 'Reset to factory default' })
      onSaved()
    } catch (e) { setMsg({ ok: false, text: e.message }) }
    finally { setSaving(false) }
  }

  const showFull = expanded || !isLarge
  const rows = showFull ? Math.max(6, Math.min(lineCount + 2, 30)) : 4

  return (
    <div style={{ border: `1.5px solid ${dirty ? t.warning : t.border}`, borderRadius: 10, padding: 16, background: '#fff' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12, marginBottom: 8 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
            <span style={{ fontWeight: 700, fontSize: 13, color: t.sidebar }}>{prompt.label || prompt.key}</span>
            <code style={{ fontSize: 10, color: t.muted, background: '#F1F5F9', padding: '2px 6px', borderRadius: 4 }}>{prompt.key}</code>
            {prompt.is_seed_default && <Badge color={t.muted}>factory default</Badge>}
            {dirty && <Badge color={t.warning}>unsaved</Badge>}
          </div>
          {prompt.description && (
            <div style={{ fontSize: 11, color: t.muted, lineHeight: 1.5 }}>{prompt.description}</div>
          )}
        </div>
        <div style={{ fontSize: 10, color: t.muted, whiteSpace: 'nowrap' }}>
          {new Date(prompt.updated_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
        </div>
      </div>

      <textarea
        value={content}
        onChange={e => setContent(e.target.value)}
        rows={rows}
        spellCheck={false}
        style={{
          width: '100%', padding: '10px 12px',
          border: `1px solid ${t.border}`, borderRadius: 8, fontSize: 12,
          fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Consolas, monospace',
          color: t.sidebar, background: '#FAFAFA', lineHeight: 1.6, resize: 'vertical',
        }}
      />

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, gap: 8 }}>
        <div style={{ display: 'flex', gap: 10, fontSize: 11, color: t.muted, alignItems: 'center' }}>
          <span>{content.length.toLocaleString()} chars</span>
          {isLarge && (
            <button onClick={() => setExpanded(!expanded)} style={{
              border: 'none', background: 'transparent', color: t.primary, cursor: 'pointer',
              fontSize: 11, fontWeight: 600,
            }}>
              {expanded ? '↑ Collapse' : '↓ Expand'}
            </button>
          )}
        </div>
        <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          {dirty && (
            <Button variant="ghost" color={t.muted} size="sm"
              onClick={() => setContent(prompt.content)} disabled={saving}>Discard</Button>
          )}
          {prompt.has_seed_default && !prompt.is_seed_default && (
            <Button variant="ghost" color={t.muted} size="sm" onClick={reset} disabled={saving}>↺ Reset</Button>
          )}
          <Button color={t.primary} size="sm" onClick={save} disabled={saving || !dirty}>
            {saving ? 'Saving…' : 'Save'}
          </Button>
        </div>
      </div>
      <Toast msg={msg} />
    </div>
  )
}

function PromptsView() {
  const [groups, setGroups] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [filter, setFilter] = useState('all')

  const load = async () => {
    setLoading(true); setError(null)
    try {
      const r = await fetch(`${API}/admin/prompts`)
      const d = await r.json()
      if (!r.ok) throw new Error(d.detail || 'Failed to load')
      setGroups(d.groups || [])
    } catch (e) { setError(e.message) }
    finally { setLoading(false) }
  }
  useEffect(() => { load() }, [])

  const visible = filter === 'all' ? groups : groups.filter(g => g.category === filter)
  const totalCount = groups.reduce((n, g) => n + g.prompts.length, 0)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <Card>
        <SectionHeader
          title={`Prompts · ${totalCount} entries`}
          action={<Button variant="ghost" color={t.muted} size="sm" onClick={load} disabled={loading}>↻ Refresh</Button>}
        />
        <div style={{ padding: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: 8, padding: '10px 14px', fontSize: 12, color: '#1E40AF', lineHeight: 1.6 }}>
            Every prompt sent to the LLM — personas, role anchors, language instructions, refusal messages, the RAG context wrapper —
            is stored here. Nothing is read from <code>.env</code> or hardcoded in the agent. Edits apply on the next chat turn,
            including in existing sessions.
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <button onClick={() => setFilter('all')} style={chipStyle(filter === 'all')}>
              All ({totalCount})
            </button>
            {groups.map(g => (
              <button key={g.category} onClick={() => setFilter(g.category)} style={chipStyle(filter === g.category)}>
                {CATEGORY_ICON[g.category] || '•'} {g.label} ({g.prompts.length})
              </button>
            ))}
          </div>
        </div>
      </Card>

      {loading && <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading prompts…</div>}
      {error && <Toast msg={{ ok: false, text: error }} />}

      {visible.map(group => (
        <Card key={group.category}>
          <SectionHeader title={`${CATEGORY_ICON[group.category] || '•'}  ${group.label}`} />
          <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
            {group.prompts.map(p => (
              <PromptEditor key={p.key} prompt={p} onSaved={load} />
            ))}
          </div>
        </Card>
      ))}
    </div>
  )
}

function chipStyle(active) {
  return {
    padding: '5px 12px', borderRadius: 20, fontSize: 11, fontWeight: 600,
    cursor: 'pointer', border: 'none',
    background: active ? t.sidebar : '#F1F5F9',
    color: active ? '#fff' : t.muted,
  }
}

// ── Avatars page ─────────────────────────────────────────────────────────

function AvatarsView({ flavor }) {
  const [avatars, setAvatars] = useState([])
  const [loading, setLoading] = useState(true)
  const [toast, setToast] = useState(null)
  const [name, setName] = useState('')
  const [piperVoiceId, setPiperVoiceId] = useState('en_US-amy-medium')
  const [file, setFile] = useState(null)
  const [busy, setBusy] = useState(false)
  const fileInputRef = useRef(null)

  const load = async () => {
    setLoading(true)
    try {
      const r = await fetch(`${API}/admin/avatars?flavor_id=${encodeURIComponent(flavor)}`)
      const d = await r.json()
      setAvatars(d.avatars || [])
    } catch (e) {
      setToast({ ok: false, text: `Failed to load: ${e.message}` })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [flavor])

  const reset = () => {
    setName(''); setFile(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const submit = async (e) => {
    e.preventDefault()
    if (!name.trim()) { setToast({ ok: false, text: 'Name is required' }); return }
    if (!file) { setToast({ ok: false, text: 'Photo is required' }); return }
    setBusy(true)
    try {
      const fd = new FormData()
      fd.append('name', name.trim())
      fd.append('flavor_id', flavor)
      fd.append('voice_id', piperVoiceId || 'en_US-amy-medium')
      fd.append('photo', file)
      const r = await fetch(`${API}/admin/avatars/face`, { method: 'POST', body: fd })
      if (!r.ok) throw new Error((await r.json()).detail || 'Request failed')
      const data = await r.json()
      setToast({ ok: true, text: `Avatar "${data.name}" added` })
      reset()
      load()
    } catch (e) {
      setToast({ ok: false, text: e.message })
    } finally {
      setBusy(false)
    }
  }

  const remove = async (id, n) => {
    if (!confirm(`Delete avatar "${n || id.slice(0, 8)}"?`)) return
    try {
      const r = await fetch(`${API}/admin/avatars/${id}`, { method: 'DELETE' })
      if (!r.ok) throw new Error('Delete failed')
      setToast({ ok: true, text: 'Avatar deleted' })
      load()
    } catch (e) {
      setToast({ ok: false, text: e.message })
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {toast && <Toast msg={toast} />}

      <Card>
        <SectionHeader title="Add a face photo avatar" />
        <div style={{ padding: 16 }}>
          <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Input label="Display name" value={name} onChange={e => setName(e.target.value)}
              placeholder="e.g. Vijay" required />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <label style={{ fontSize: 12, fontWeight: 600, color: t.muted }}>
                Face photo <span style={{ color: t.danger }}>*</span>
              </label>
              <input ref={fileInputRef} type="file" accept="image/*"
                onChange={e => setFile(e.target.files?.[0] || null)}
                style={{ padding: '9px 12px', border: `1.5px solid ${t.border}`, borderRadius: 8, fontSize: 13, background: '#fff' }} />
              <span style={{ fontSize: 11, color: t.muted }}>
                Forward-facing portrait works best. Stored in <strong>avatar-service</strong> on port 8002 and animated locally
                (no cloud calls). Web client overlays a 2D mouth + idle blinks while TTS speaks.
              </span>
            </div>
            <Input label="Voice id" value={piperVoiceId} onChange={e => setPiperVoiceId(e.target.value)}
              placeholder="en_US-amy-medium"
              hint="Any edge-tts voice. Indian English: en-IN-NeerjaNeural. Tamil: ta-IN-PallaviNeural. Hindi: hi-IN-SwaraNeural. Aliases like en_US-amy-medium also work." />

            <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
              <Button type="submit" disabled={busy}>{busy ? 'Adding…' : 'Add avatar'}</Button>
              <Button type="button" variant="ghost" color={t.muted} onClick={reset}>Reset</Button>
            </div>
          </form>
        </div>
      </Card>

      <Card>
        <SectionHeader title={`Avatars for ${FLAVORS.find(f => f.id === flavor)?.label || flavor}`} />
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading…</div>
        ) : avatars.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>
            No avatars yet. Add one above.
          </div>
        ) : (
          <div style={{ padding: 16, display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 12 }}>
            {avatars.map(a => (
              <AvatarCard key={a.id} avatar={a} onDelete={() => remove(a.id, a.name)} />
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}

function AvatarCard({ avatar, onDelete }) {
  const sourceBadge = avatar.face_avatar_id
    ? { label: '📸 Face Photo', color: '#0EA5E9' }
    : { label: 'Unknown', color: t.muted }
  const linkHref = avatar.face_avatar_id
    ? `${API}/avatar-svc/${avatar.face_avatar_id}/photo`
    : null
  const linkLabel = 'View photo ↗'

  return (
    <div style={{ border: `1px solid ${t.border}`, borderRadius: 10, padding: 14, background: '#fff', display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontWeight: 600, fontSize: 14, color: t.sidebar, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {avatar.name || avatar.id.slice(0, 8)}
          </div>
          <div style={{ fontSize: 11, color: t.muted, marginTop: 2, fontFamily: 'ui-monospace, SFMono-Regular, monospace' }}>
            {avatar.id.slice(0, 12)}…
          </div>
        </div>
        <Badge color={sourceBadge.color}>{sourceBadge.label}</Badge>
      </div>

      <div style={{ fontSize: 11, color: t.muted }}>
        Added {new Date(avatar.created_at).toLocaleString()}
      </div>

      {linkHref && (
        <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
          <a href={linkHref} target="_blank" rel="noreferrer" className="source-link"
            style={{ fontSize: 11, fontWeight: 600, color: t.info }}>{linkLabel}</a>
        </div>
      )}

      <div style={{ marginTop: 'auto', paddingTop: 8, borderTop: `1px solid ${t.border}`, display: 'flex', justifyContent: 'flex-end' }}>
        <Button size="sm" variant="ghost" color={t.danger} onClick={onDelete}>Delete</Button>
      </div>
    </div>
  )
}

// ── Content CMS (News + Events) ────────────────────────────────────────────
function CmsView({ flavor, kind }) {
  const isNews = kind === 'news'
  const empty = isNews
    ? { title: '', summary: '', category: 'Party', image_url: '' }
    : { title: '', description: '', location: '', event_type: 'Rally', image_url: '', starts_at: '' }
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const [busy, setBusy] = useState(false)
  const [f, setF] = useState(empty)

  const load = async () => {
    setLoading(true)
    try { const r = await fetch(`${API}/${kind}?flavor_id=${flavor}`); setItems((await r.json())[kind] || []) }
    catch { setItems([]) }
    finally { setLoading(false) }
  }
  useEffect(() => { load() }, [flavor, kind])

  const set = (k, v) => setF(prev => ({ ...prev, [k]: v }))

  const submit = async e => {
    e.preventDefault()
    if (!f.title.trim()) { setToast({ ok: false, text: 'Title is required' }); return }
    setBusy(true)
    try {
      const r = await fetch(`${API}/admin/${kind}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ flavor_id: flavor, ...f }),
      })
      if (!r.ok) throw new Error((await r.json()).detail || 'Request failed')
      setToast({ ok: true, text: `${isNews ? 'News' : 'Event'} published` })
      setF(empty); load()
    } catch (e) { setToast({ ok: false, text: e.message }) }
    finally { setBusy(false) }
  }

  const remove = async (id, title) => {
    if (!confirm(`Delete "${title}"?`)) return
    try {
      const r = await fetch(`${API}/admin/${kind}/${id}`, { method: 'DELETE' })
      if (!r.ok) throw new Error('Delete failed')
      setToast({ ok: true, text: 'Deleted' }); load()
    } catch (e) { setToast({ ok: false, text: e.message }) }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {toast && <Toast msg={toast} />}
      <Card>
        <SectionHeader title={isNews ? 'Publish news' : 'Publish event'} />
        <div style={{ padding: 16 }}>
          <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Input label="Title" value={f.title} onChange={e => set('title', e.target.value)} required
              placeholder={isNews ? 'e.g. TVK App Launch' : 'e.g. Youth Wing Rally'} />
            {isNews ? (
              <>
                <Textarea label="Summary" value={f.summary} onChange={e => set('summary', e.target.value)} rows={3} />
                <Input label="Category" value={f.category} onChange={e => set('category', e.target.value)} placeholder="Party / Event / Policy…" />
              </>
            ) : (
              <>
                <Textarea label="Description" value={f.description} onChange={e => set('description', e.target.value)} rows={3} />
                <Input label="Location" value={f.location} onChange={e => set('location', e.target.value)} placeholder="e.g. Coimbatore" />
                <Input label="Type" value={f.event_type} onChange={e => set('event_type', e.target.value)} placeholder="Rally / Meeting / Convention…" />
                <Input label="Starts at" type="datetime-local" value={f.starts_at} onChange={e => set('starts_at', e.target.value)} hint="Leave empty for now." />
              </>
            )}
            <Input label="Image URL" value={f.image_url} onChange={e => set('image_url', e.target.value)} placeholder="https://… (optional)" />
            <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
              <Button type="submit" disabled={busy}>{busy ? 'Publishing…' : 'Publish'}</Button>
              <Button type="button" variant="ghost" color={t.muted} onClick={() => setF(empty)}>Reset</Button>
            </div>
          </form>
        </div>
      </Card>

      <Card>
        <SectionHeader title={`${isNews ? 'News' : 'Events'} for ${FLAVORS.find(x => x.id === flavor)?.label || flavor}`} />
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading…</div>
        ) : items.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Nothing published yet.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {items.map(it => (
              <div key={it.id} className="hover-row" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: `1px solid ${t.border}` }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: t.sidebar }}>{it.title}</div>
                  <div style={{ fontSize: 11, color: t.muted, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {isNews ? (it.summary || '') : [it.location, it.description].filter(Boolean).join(' · ')}
                  </div>
                </div>
                <Badge color={t.info}>{isNews ? it.category : it.type}</Badge>
                <span style={{ fontSize: 11, color: t.muted, whiteSpace: 'nowrap' }}>{it.date} · {it.time}</span>
                <Button size="sm" variant="ghost" color={t.danger} onClick={() => remove(it.id, it.title)}>Delete</Button>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}

function ToolkitCmsView({ flavor }) {
  const empty = { kind: 'Posters', title: '', image_url: '', link_url: '', subtitle: '' }
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const [busy, setBusy] = useState(false)
  const [f, setF] = useState(empty)

  const load = async () => {
    setLoading(true)
    try { const r = await fetch(`${API}/toolkit?flavor_id=${flavor}`); setItems((await r.json()).items || []) }
    catch { setItems([]) }
    finally { setLoading(false) }
  }
  useEffect(() => { load() }, [flavor])
  const set = (k, v) => setF(prev => ({ ...prev, [k]: v }))

  const submit = async e => {
    e.preventDefault()
    if (!f.image_url.trim() && !f.title.trim()) { setToast({ ok: false, text: 'Image URL or title required' }); return }
    setBusy(true)
    try {
      const r = await fetch(`${API}/admin/toolkit`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ flavor_id: flavor, ...f }),
      })
      if (!r.ok) throw new Error((await r.json()).detail || 'Request failed')
      setToast({ ok: true, text: 'Toolkit item published' })
      setF({ ...empty, kind: f.kind }); load()
    } catch (e) { setToast({ ok: false, text: e.message }) }
    finally { setBusy(false) }
  }

  const remove = async (id, title) => {
    if (!confirm(`Delete "${title || id}"?`)) return
    try {
      const r = await fetch(`${API}/admin/toolkit/${id}`, { method: 'DELETE' })
      if (!r.ok) throw new Error('Delete failed')
      setToast({ ok: true, text: 'Deleted' }); load()
    } catch (e) { setToast({ ok: false, text: e.message }) }
  }

  const kinds = ['Posters', 'Media', 'Slogans', 'Hashtags']
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {toast && <Toast msg={toast} />}
      <Card>
        <SectionHeader title="Publish campaign toolkit item" />
        <div style={{ padding: 16 }}>
          <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <label style={{ fontSize: 12, fontWeight: 600, color: t.muted }}>Kind</label>
            <select value={f.kind} onChange={e => set('kind', e.target.value)}
              style={{ padding: '8px 10px', borderRadius: 8, border: `1px solid ${t.border}`, fontSize: 13 }}>
              {kinds.map(k => <option key={k} value={k}>{k}</option>)}
            </select>
            <Input label="Title" value={f.title} onChange={e => set('title', e.target.value)} placeholder="Optional caption" />
            <Input label="Image URL" value={f.image_url} onChange={e => set('image_url', e.target.value)} placeholder="https://… poster / thumbnail" />
            <Input label="Link URL" value={f.link_url} onChange={e => set('link_url', e.target.value)} hint="For Media: YouTube URL or video id." />
            <Input label="Subtitle" value={f.subtitle} onChange={e => set('subtitle', e.target.value)} placeholder="Optional (channel / meta)" />
            <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
              <Button type="submit" disabled={busy}>{busy ? 'Publishing…' : 'Publish'}</Button>
              <Button type="button" variant="ghost" color={t.muted} onClick={() => setF({ ...empty, kind: f.kind })}>Reset</Button>
            </div>
          </form>
        </div>
      </Card>
      <Card>
        <SectionHeader title={`Toolkit for ${FLAVORS.find(x => x.id === flavor)?.label || flavor}`} />
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading…</div>
        ) : items.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Nothing published yet — the app shows built-in samples.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {items.map(it => (
              <div key={it.id} className="hover-row" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: `1px solid ${t.border}` }}>
                {it.image_url && <img src={it.image_url} alt="" style={{ width: 44, height: 44, borderRadius: 6, objectFit: 'cover' }} />}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: t.sidebar }}>{it.title || '(no title)'}</div>
                  <div style={{ fontSize: 11, color: t.muted, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{it.subtitle || it.link_url || ''}</div>
                </div>
                <Badge color={t.info}>{it.kind}</Badge>
                <Button size="sm" variant="ghost" color={t.danger} onClick={() => remove(it.id, it.title)}>Delete</Button>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}

function ComplaintsView() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState(null)
  const STATUSES = ['Pending', 'In-Progress', 'Resolved']

  const load = async () => {
    setLoading(true)
    try { const r = await fetch(`${API}/admin/complaints`); setItems((await r.json()).complaints || []) }
    catch { setItems([]) }
    finally { setLoading(false) }
  }
  useEffect(() => { load() }, [])

  const setStatus = async (id, status) => {
    try {
      const r = await fetch(`${API}/admin/complaints/${id}/status?status=${encodeURIComponent(status)}`, { method: 'POST' })
      if (!r.ok) throw new Error('Update failed')
      setToast({ ok: true, text: `Marked ${status}` }); load()
    } catch (e) { setToast({ ok: false, text: e.message }) }
  }

  const color = s => s === 'Resolved' ? t.success : s === 'In-Progress' ? t.info : t.danger

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {toast && <Toast msg={toast} />}
      <Card>
        <SectionHeader title="Citizen complaints" />
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>Loading…</div>
        ) : items.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: t.muted, fontSize: 13 }}>No complaints raised yet.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {items.map(it => (
              <div key={it.id} className="hover-row" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: `1px solid ${t.border}` }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: t.sidebar }}>{it.title}</div>
                  <div style={{ fontSize: 11, color: t.muted, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {[it.category, it.description].filter(Boolean).join(' · ')}
                    {it.has_attachment ? ` · 📎 ${it.attachment_name || 'attachment'}` : ''}
                  </div>
                </div>
                <Badge color={color(it.status)}>{it.status}</Badge>
                <select value={it.status} onChange={e => setStatus(it.id, e.target.value)}
                  style={{ padding: '6px 8px', borderRadius: 6, border: `1px solid ${t.border}`, fontSize: 12 }}>
                  {STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}

// ── Sidebar ──────────────────────────────────────────────────────────────
const NAV = [
  { section: 'KNOWLEDGE BASE' },
  { id: 'documents', icon: '📚', label: 'Documents' },
  { id: 'test', icon: '🔍', label: 'Test Retrieval' },
  { id: 'audit', icon: '📋', label: 'Audit Log' },
  { section: 'CONTENT (CMS)' },
  { id: 'news', icon: '📰', label: 'News' },
  { id: 'events', icon: '📅', label: 'Events' },
  { id: 'toolkit', icon: '🎨', label: 'Campaign Toolkit' },
  { id: 'complaints', icon: '📮', label: 'Complaints' },
  { section: 'AVATAR' },
  { id: 'avatars', icon: '🧑', label: 'Avatars' },
  { section: 'PROMPT CONFIG' },
  { id: 'prompts', icon: '🎭', label: 'All Prompts' },
]

function Sidebar({ active, onNav, flavor, setFlavor, docCount }) {
  return (
    <div style={{ width: 200, background: t.sidebar, minHeight: '100vh', flexShrink: 0, display: 'flex', flexDirection: 'column', position: 'fixed', top: 0, left: 0, bottom: 0 }}>
      {/* Brand + flavor switcher */}
      <div style={{ padding: '20px 16px 16px', borderBottom: `1px solid ${t.sidebarBorder}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
          <span style={{ fontSize: 20 }}>🧠</span>
          <div>
            <div style={{ color: '#fff', fontWeight: 700, fontSize: 13, lineHeight: 1 }}>RAG Admin</div>
            <div style={{ color: t.sidebarText, fontSize: 11, marginTop: 2 }}>Knowledge Base</div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {FLAVORS.map(f => (
            <button key={f.id} onClick={() => setFlavor(f.id)} style={{
              flex: 1, padding: '5px 0', borderRadius: 6, border: 'none', fontSize: 11, fontWeight: 600, cursor: 'pointer',
              background: flavor === f.id ? f.color : 'rgba(255,255,255,0.08)',
              color: flavor === f.id ? '#fff' : t.sidebarText,
            }}>{f.label}</button>
          ))}
        </div>
      </div>

      {/* Nav */}
      <nav style={{ padding: '8px 0', flex: 1 }}>
        {NAV.map((item, i) => item.section ? (
          <div key={i} style={{ padding: '12px 16px 4px', fontSize: 10, fontWeight: 700, color: 'rgba(148,163,184,0.5)', letterSpacing: '0.08em' }}>{item.section}</div>
        ) : (
          <button key={item.id} onClick={() => onNav(item.id)} className="nav-item" style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '9px 16px',
            border: 'none', cursor: 'pointer', textAlign: 'left',
            background: active === item.id ? t.sidebarActive : 'transparent',
            color: active === item.id ? '#fff' : t.sidebarText,
            borderLeft: active === item.id ? `3px solid ${t.primary}` : '3px solid transparent',
            fontSize: 13, fontWeight: active === item.id ? 600 : 400,
          }}>
            <span style={{ fontSize: 14, width: 18, textAlign: 'center' }}>{item.icon}</span>
            {item.label}
          </button>
        ))}
      </nav>

      {/* Footer */}
      <div style={{ padding: '12px 16px', borderTop: `1px solid ${t.sidebarBorder}` }}>
        <div style={{ fontSize: 11, color: t.sidebarText }}>{docCount} documents indexed</div>
        <div style={{ fontSize: 10, color: 'rgba(148,163,184,0.4)', marginTop: 2 }}></div>
      </div>
    </div>
  )
}

// ── FAB ───────────────────────────────────────────────────────────────────
function AddFab({ onClick }) {
  return (
    <button
      onClick={onClick}
      className="fab-btn"
      style={{
        position: 'fixed', bottom: 32, right: 32, zIndex: 100,
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '13px 22px', borderRadius: 50, border: 'none',
        background: t.primary, color: '#fff',
        fontSize: 14, fontWeight: 700, cursor: 'pointer',
      }}
    >
      <span style={{ fontSize: 18, lineHeight: 1 }}>＋</span>
      Add Content
    </button>
  )
}

// ── App ───────────────────────────────────────────────────────────────────
export default function App() {
  const [flavor, setFlavor] = useState('tn-tvk')
  const [page, setPage] = useState('documents')
  const [showAdd, setShowAdd] = useState(false)
  const { docs, loading, reload } = useDocuments(flavor)

  const handleDelete = async id => {
    if (!confirm(`Delete document #${id}? This cannot be undone.`)) return
    await fetch(`${API}/admin/documents/${id}`, { method: 'DELETE' })
    reload()
  }

  const typeCount = type => docs.filter(d => sourceType(d.source).label === type).length

  return (
    <>
      <GlobalStyle />
      <div style={{ display: 'flex', minHeight: '100vh' }}>
        <Sidebar active={page} onNav={setPage} flavor={flavor} setFlavor={setFlavor} docCount={docs.length} />

        <main style={{ marginLeft: 200, flex: 1, padding: 24, minHeight: '100vh' }}>
          {/* Stats */}
          {(page === 'documents' || page === 'test') && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
              <StatCard label="Total Documents" value={docs.length} icon="📚" color={t.primary} />
              <StatCard label="Manual / File" value={typeCount('Manual') + typeCount('File')} icon="📝" color="#8B5CF6" />
              <StatCard label="From URLs" value={typeCount('URL')} icon="🌐" color={t.info} />
              <StatCard label="YouTube" value={typeCount('YouTube')} icon="▶" color={t.danger} />
            </div>
          )}

          {page === 'documents' && <DocumentsView flavor={flavor} docs={docs} loading={loading} onDelete={handleDelete} />}
          {page === 'test' && <TestQueryView flavor={flavor} />}
          {page === 'audit' && <AuditLogView />}
          {page === 'prompts' && <PromptsView />}
          {page === 'avatars' && <AvatarsView flavor={flavor} />}
          {page === 'news' && <CmsView flavor={flavor} kind="news" />}
          {page === 'events' && <CmsView flavor={flavor} kind="events" />}
          {page === 'toolkit' && <ToolkitCmsView flavor={flavor} />}
          {page === 'complaints' && <ComplaintsView />}
        </main>

        {/* Floating Add Content button — only on the knowledge-base document pages */}
        {['documents', 'test', 'audit'].includes(page) && <AddFab onClick={() => setShowAdd(true)} />}

        {/* Add Content modal */}
        {showAdd && (
          <AddContentModal
            flavor={flavor}
            onClose={() => setShowAdd(false)}
            onAdded={() => { reload(); setShowAdd(false) }}
          />
        )}
      </div>
    </>
  )
}
