import { StrictMode, useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import './style.css'

function App() {
  const [status, setStatus] = useState('loading')

  useEffect(() => {
    const controller = new AbortController()
    fetch('/api/actuator/health', { signal: controller.signal })
      .then((response) => {
        if (!response.ok) throw new Error('Serviço indisponível')
        return response.json()
      })
      .then((health) => setStatus(health.status === 'UP' ? 'online' : 'offline'))
      .catch((error) => {
        if (error.name !== 'AbortError') setStatus('offline')
      })
    return () => controller.abort()
  }, [])

  return (
    <main>
      <header>
        <span className="brand" aria-hidden="true">RD</span>
        <p>APS · BANCO DE DADOS 2</p>
      </header>
      <section className="intro">
        <p className="eyebrow">PROJETO REDE DOR</p>
        <h1>Informações conectadas.<br />Cuidado organizado.</h1>
        <p className="description">
          Um lugar para organizar pacientes, profissionais e atendimentos.
        </p>
      </section>
      <section className="card" aria-labelledby="project-status">
        <div>
          <h2 id="project-status">Projeto em desenvolvimento</h2>
          <p>Os cadastros e os fluxos de atendimento serão adicionados nas próximas etapas.</p>
        </div>
        <p className={`status ${status}`} role="status" aria-live="polite">
          <span aria-hidden="true" />
          {status === 'loading' && 'Verificando conexão…'}
          {status === 'online' && 'Sistema conectado'}
          {status === 'offline' && 'Sistema indisponível no momento'}
        </p>
      </section>
      <footer>IFPE Campus Paulista · Rede Dor</footer>
    </main>
  )
}

createRoot(document.getElementById('root')).render(
  <StrictMode><App /></StrictMode>,
)
