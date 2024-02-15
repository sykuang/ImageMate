import { app, BrowserWindow, ipcMain, session, MenuItemConstructorOptions, Menu, dialog } from 'electron';
import { join, dirname, basename, extname } from 'path';
import { readFileSync, statSync, readdirSync } from 'fs';
// import Store from 'electron-store';
import store from './store';
// const config = new Store()
interface ImageInfo {
  path: string;
}
var mainWindow: BrowserWindow;
var currentIndex: number = -1;
var openFileName: string = "";
const WindowTitleBarPadding = 32;
const files: string[] = [];
const ImageExtensions = [".jpeg",
  ".jpg",
  ".png",
  ".gif",
  ".bmp",
  ".ico",
  ".tiff",
  ".tif",
  ".raw",
  ".svg",
  ".webp"];
const menuTemplate: MenuItemConstructorOptions[] = [{
  label: 'File',
  submenu: [
    {
      label: 'Open', click: async () => {
        const file = await dialog.showOpenDialog({ properties: ['openFile'] });
        if (file.canceled) return;
        openFileName = file.filePaths[0];
        getImageFromFolder(dirname(openFileName), openFileName);
        setImage(openFileName, 0);

      }
    },
    { "role": "quit" }]
}];
async function getImageFromFolder(folder: string, openFileName: string) {
  if (!folder) return;
  //Clear files if we are opening a new folder
  files.length = 0;
  var checkFile = async (f: string) => {
    try {
      const stats = await statSync(f);
      if (stats.isFile() && ImageExtensions.includes(extname(f).toLowerCase())) {
        files.push(f);
      }
    } catch (e) {
      console.error(e);
    }
  };
  const _files = readdirSync(folder);
  for (const f of _files) {
    const fullPath = join(folder, f)
    await checkFile(fullPath);
  }
  files.sort();
  currentIndex = files.indexOf(openFileName);
  console.log("currentIndex:", currentIndex, "files.length:", files.length);
}
async function setImage(filepath: string, index: number) {
  console.log("Set Image:", filepath);
  const img = readFileSync(filepath).toString('base64');
  mainWindow.webContents.send('open-file', {
    itemImageSrc: "data:img/png;base64," + img,
    alt: filepath,
    title: basename(filepath),
  }, index)
}
async function setIndex(index: number) {
  if (index >= 0 && index < files.length) {
    mainWindow.webContents.send('set-index', index);
  }
}
async function createWindow() {
  mainWindow = new BrowserWindow({
    width: store.get('WinBounds.width', 800),
    height: store.get('WinBounds.height', 600),
    autoHideMenuBar: true,
    webPreferences: {
      preload: join(__dirname, 'preload.js'),
      nodeIntegration: true,
      contextIsolation: true,
      devTools: !app.isPackaged,
    }
  });
  Menu.setApplicationMenu(Menu.buildFromTemplate(menuTemplate));
  mainWindow.removeMenu();
  mainWindow.setPosition(store.get('winBounds.x'), store.get('winBounds.y'));
  if (process.env.NODE_ENV === 'development') {
    const rendererPort = process.argv[2];
    mainWindow.loadURL(`http://localhost:${rendererPort}`);
  }
  else {
    mainWindow.loadFile(join(app.getAppPath(), 'renderer', 'index.html'));
  }

  mainWindow.webContents.on('did-finish-load', async () => {
    if (openFileName === "") return;
    // First load the image
    setImage(openFileName, 0);
  });
  mainWindow.on('close', () => {
    store.set("WinBounds", mainWindow.getBounds())
  })
  getImageFromFolder(dirname(openFileName), openFileName);
}

app.whenReady().then(() => {
  if (process.env.NODE_ENV === 'development' && process.env.DEBUG_FILE) {
    console.log(process.env.DEBUG_FILE);
    var _file = process.env.DEBUG_FILE;
    openFileName = _file;

  }
  createWindow();

  session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
    callback({
      responseHeaders: {
        ...details.responseHeaders,
        'Content-Security-Policy': ['script-src \'self\'']
      }
    })
  })
  app.on('activate', function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', function () {
  // if (process.platform !== 'darwin') 
  app.quit()
});

// If process is started with a file, save it for later
app.on('open-file', (event, _file) => {
  openFileName = _file;
});

ipcMain.on('message', (event, message) => {
  console.log(message);
});
ipcMain.on("keyPress", (event, key) => {
  console.log(key);
  // if current index is -1, we don't have any image to show
  if (currentIndex < 0) {
    setImage(openFileName, 0);
  }
  else {
    if (key === "ArrowLeft") {
      currentIndex = currentIndex === 0 ? currentIndex = files.length - 1 : currentIndex - 1;
    } else if (key === "ArrowRight") {
      currentIndex = (currentIndex + 1) % files.length;
    }
    setImage(files[currentIndex], currentIndex);
  }
});