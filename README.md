# TradeUnion

A simple World of Warcraft addon that can paste English to Chinese translations into chat. Designed to help Western players communicate on Titan Reforged servers.

## Features

*   **Quick Translation**: Search for common phrases in English and see their Simplified Chinese translations.
*   **Keyboard Navigation**: Use Up/Down arrows to navigate results and Enter to paste.
*   **Smart Pasting**:
    *   Pastes directly into your active chat window.
    *   Preserves existing text in the chat box.
*   **Keybinding Support**: Bind a hotkey to open the search window instantly (even while typing!).

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

You can easily add your own phrases to the translation table.

1.  Open the `Translations.lua` file in the `TradeUnion` addon folder with a text editor (like Notepad, VS Code, etc.).
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

## Slash Commands

*   `/tu` or `/tradeunion`: Toggles the search window.
