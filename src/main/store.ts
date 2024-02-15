import Store, { Schema } from "electron-store";
interface UserData {
    WinBounds: {
        x: number;
        y: number;
        width: number;
        height: number;
    }
}
const schema: Schema<UserData> = {
    WinBounds: {
        type: 'object',
        properties: {
            x: {
                type: 'number',
                minimum: 0,
            },
            y: {
                type: 'number',
                minimum: 0,
            },
            width: {
                type: 'number',
                minimum: 0,
            },
            height: {
                type: 'number',
                minimum: 0,
            },
        },
        default: {
            x: 0,
            y: 0,
            width: 800,
            height: 600,
        },
    },
}
const store = new Store<UserData>({ schema });
export default store;