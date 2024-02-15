/**
 * Should match main/preload.ts for typescript support in renderer
 */
interface ImgObj {
  itemImageSrc: string,
  alt: string,
  title: string,
}
export default interface ElectronApi {
  sendMessage: (message: string) => void
  onOpenFile: (callback: (path: ImgObj) => void) => void
  onPageUp: () => void
  onPageDown: () => void
  openImage: (path: string) => string
}

declare global {
  interface Window {
    electronAPI: ElectronApi,
  }
}
