import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import MainFrame from "./MainFrame.jsx";

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <MainFrame />
  </StrictMode>,
)
