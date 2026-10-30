
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from '@/App';
import { BrowserRouter } from 'react-router-dom';
import GlobalLoadingIndicator from '@/components/common/GlobalLoadingIndicator';

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error("Could not find root element to mount to");
}

const root = ReactDOM.createRoot(rootElement);
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <GlobalLoadingIndicator />
      <App />
    </BrowserRouter>
  </React.StrictMode>
);
