# TradeUnion

A simple World of Warcraft addon that can paste English to Chinese translations into chat. Designed to help Western players communicate on Titan Reforged servers.

## Features

*   **Quick Translation**: Search for common phrases in English and see their Simplified Chinese translations.
*   **Keyboard Navigation**: Use Up/Down arrows to navigate results and Enter to paste.
*   **Smart Pasting**:
    *   Pastes directly into your active chat window.
    *   Preserves existing text in the chat box.
*   **Keybinding Support**: Bind a hotkey to open the search window instantly (even while typing).

## How to Use

1.  **Install**: Ensure the addon is installed in your `Interface\AddOns` folder.
2.  **Keybinding**:
    *   Open the Game Menu (Esc) -> **Key Bindings**.
    *   Scroll down to the **Trade Union** category.
    *   Bind a key to **Open**.
3.  **Search & Paste**:
    *   Press your bound hotkey.
    *   Type an English phrase (e.g., "invite", "tank", "wts").
    *   Use **Up/Down** arrows to highlight the desired translation.
    *   Press **Enter** (or click) to paste the Chinese translation into your chat.

## Adding More Translations

You can easily add your own phrases to translate via in-game command:

*   `/tu add {en} {cn}`: Adds a new translation.
    *   Example: `/tu add English 英语`
    *   Enclose multiple words in quotes: `/tu add "English Speaker" "英语演讲者"`

You alternatively add translations directly to the translations table.

1.  Open the `Translations.lua` file in the `TradeUnion` addon folder with a text editor.
2.  Add a new line to the `addon.Translations` table following the format:
    ```lua
    ["English Phrase"] = "Chinese Translation",
    ```
3.  **Example**:
    ```lua
    addon.Translations = {
        ["Hello"] = "你好",
        -- ... existing entries ...
        ["My New Phrase"] = "我的新短语", -- Add your new entry here
    }
    ```
4.  Save the file and reload your UI in-game (`/reload`) to see the changes.

## Sharing and Importing Translations

This system allows the community to build and share translation lists easily.

**For Contributors (e.g., Chinese speakers):**
1.  Add new translations using `/tu add English 英语` or by editing `Translations.lua`.
2.  Type `/tu export` to open a window containing all your translations.
3.  Copy the text (Ctrl+C) and share it with the community (Discord, forums, etc.).

**For Users:**
1.  Copy the translation list provided by a contributor.
2.  Type `/tu import` in-game.
3.  Paste the text (Ctrl+V) into the window and click **Import**.

## Slash Commands

*   `/tu`: Lists available commands.
*   `/tu open`: Opens the search window. Prefer setting a keybinding over using this command.
*   `/tu add {en} {cn}`: Adds a new translation.
    *   Example: `/tu add English 英语`
    *   Enclose multiple words in quotes: `/tu add "English Speaker" "英语演讲者"`
*   `/tu remove {en}`: Removes a translation.
    *   Example: `/tu remove English`
*   `/tu export`: Opens a window with all translations in a copy-able format.
*   `/tu import`: Opens a window to paste and import translations (Lua table format).
