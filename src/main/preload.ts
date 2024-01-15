import {contextBridge, ipcRenderer} from 'electron';
import fs from 'fs';
contextBridge.exposeInMainWorld('electronAPI', {
  sendMessage: (message: string) => ipcRenderer.send('message', message),
  onPageDown: () => ipcRenderer.send('keyPress', "ArrowRight"),
  onPageUp: () => ipcRenderer.send('keyPress', "ArrowLeft"),
  onOpenFile:(callback) => ipcRenderer.on('open-file', (event, data) => callback(data)),
  onSetIndex:(callback) => ipcRenderer.on('set-index', (event, data) => callback(data)),
})
