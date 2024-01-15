/**
 * Should match main/preload.ts for typescript support in renderer
 */
export default interface ElectronApi {
  sendMessage: (message: string) => void
  onOpenFile: (callback: (path: string) => void) => void
  onPageUp:() => void
  onPageDown:() => void
  openImage: (path: string) => string
}

declare global {
  interface Window {
    electronAPI: ElectronApi,
  }
}
