<div align="center"> 

# ImageMate
![Image Alt text](/images/icon/icon.png)

</div>

## About

This is a simple Image viewer for OS X. You can use arrow key left and right to browsing the image in the folder. 

## Getting started

Clone this repository: `git clone https://github.com/sykuang/ImageMate.git`


### Install dependencies ⏬

```bash
npm install
```

### Start developing ⚒️

```bash
npm run dev
```

## Additional Commands

```bash
npm run dev # starts application with hot reload
npm run build # builds application, distributable files can be found in "dist" folder

# OR

npm run build:win # uses windows as build target
npm run build:mac # uses mac as build target
npm run build:linux # uses linux as build target
```

## Project Structure

```bash
- scripts/ # all the scripts used to build or serve your application, change as you like.
- src/
  - main/ # Main thread (Electron application source)
  - renderer/ # Renderer thread (VueJS application source)
```