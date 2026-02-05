# DevChaCha Robbery System

A comprehensive, multiplayer-ready robbery system for **RedM (RSG-Core)**. This resource integrates both **General Store** and **Bank Robberies** into a single, optimized package using `ox_lib` and `ox_target`.

## Features

*   **Dual System**: Handles both Store Registers and Bank Vaults.
*   **Third Eye Integration**: All interactions use `ox_target` for seamless gameplay.
*   **Multiplayer Sync**: Vault states and timers are synchronized for all players using `GlobalState`.
*   **Bank Robberies**:
    *   **Requirement**: Bandit/Thief with **Dynamite** (`tnt`).
    *   **Process**:
        1.  Plant TNT at the vault.
        2.  **5-Second Fuse**: You have 5 seconds to run to safety before the blast.
        3.  **Heat Period**: After the explosion, the vault is too hot/dangerous to loot immediately (default: **10 minutes**).
        4.  **Looting**: Once the smoke clears, loot the vault for high valuable rewards.
*   **Store Robberies**:
    *   **Requirement**: **Lockpick** (`lockpick`).
    *   **Process**:
        1.  Target the register (`Rob Store`).
        2.  Complete a Lockpick minigame to disable the security mechanism.
        3.  **Police Alert**: Lawmen are alerted immediately.
        4.  **Waiting Period**: The safe/register takes time to unlock (default: **5 minutes**).
        5.  **Looting**: Return after the timer expires to grab the cash and items.
*   **Door Breaching**:
    *   Breach locked back doors at Stores (Easy) or Banks (Hard) to gain entry or escape.
*   **Police System**:
    *   Configurable minimum lawmen required online.
    *   Alerts sent to specified jobs (`sheriff`, `police`, `marshal`) upon robbery start.
*   **Cooldowns**:
    *   Server-side cooldowns (default: 2 hours) to prevent spamming.

## Dependencies

*   [rsg-core](https://github.com/Rexshack-Gaming/rsg-core)
*   [ox_lib](https://github.com/overextended/ox_lib)
*   [ox_target](https://github.com/overextended/ox_target)

## Installation

1.  **Download & Extract**:
    *   Place the `devchacha-robbery` folder into your server's `resources` directory.

2.  **Add Items**:
    *   Ensure your `rsg-core/shared/items.lua` contains the required items:
        *   `lockpick`
        *   `tnt` (or `dynamite`, adjust in `config.lua`)
        *   Reward items: `gold_bar`, `diamond`, `gold_ring`, `rolex`, `candy`, `bread`.

3.  **Server Config**:
    *   Add the following line to your `server.cfg` or `resources.cfg`:
    ```cfg
    ensure ox_lib
    ensure ox_target
    ensure rsg-core
    ensure devchacha-robbery
    ```

4.  **Configuration**:
    *   Open `config.lua` to adjust:
        *   **Police Requirement**: Set `Config.Police.RequiredForBank` (default is 0 for testing).
        *   **Timers**: Adjust `Config.RobberyDuration` (Store wait) and `Config.BankRobberyDuration` (Bank wait).
        *   **Rewards**: Change the min/max cash and item drops.
        *   **Locations**: Add or remove store/bank coordinates.

5.  **RSG-Banking Configuration**
    *   To allow players to access the bank vaults, ensure that the doors in `rsg-banking` are set to **unlocked** (state 0). Update `Config.BankDoors` in `rsg-banking/config.lua` as follows:
    ```lua
    Config.BankDoors = {
        -- valentine ( open = 0 / locked = 1)
        { door = 2642457609, state = 0 }, -- main door
        { door = 3886827663, state = 0 }, -- main door
        { door = 1340831050, state = 0 }, -- bared right
        { door = 2343746133, state = 0 }, -- bared left
        { door = 334467483,  state = 0 }, -- inner door1
        { door = 3718620420, state = 0 }, -- inner door2
        { door = 576950805,  state = 0 }, -- valut

        -- rhodes  ( open = 0 / locked = 1)
        { door = 3317756151, state = 0 }, -- main door
        { door = 3088209306, state = 0 }, -- main door
        { door = 2058564250, state = 0 }, -- inner door1
        { door = 3142122679, state = 0 }, -- inner door2
        { door = 1634148892, state = 0 }, -- inner door3
        { door = 3483244267, state = 0 }, -- valut

        -- saint denis ( open = 0 / locked = 1)
        { door = 2158285782, state = 0 }, -- main door
        { door = 1733501235, state = 0 }, -- main door
        { door = 2089945615, state = 0 }, -- main door
        { door = 2817024187, state = 0 }, -- main door
        { door = 1830999060, state = 0 }, -- inner private door
        { door = 965922748,  state = 0 }, -- manager door
        { door = 1634115439, state = 0 }, -- manager door
        { door = 1751238140, state = 0 }, -- vault

        -- blackwater
        { door = 531022111,  state = 0 }, -- main door
        { door = 2117902999, state = 0 }, -- inner door
        { door = 2817192481, state = 0 }, -- manager door
        { door = 1462330364, state = 0 }, -- vault door
        
        -- armadillo
        { door = 3101287960, state = 0 }, -- main door
        { door = 3550475905, state = 0 }, -- inner door
        { door = 1329318347, state = 0 }, -- inner door
        { door = 1366165179, state = 0 }, -- back door
    }
    ```

## How It Works

### Robbing a Store
1.  **Target** a Cash Register at any General Store (using `Alt` / Third Eye).
2.  Select **Rob Store**.
3.  Complete the **Lockpick** minigame.
4.  **Wait**: The mechanism takes **5 minutes** (default) to loosen. Police are alerted.
5.  After the time passes, **Target** the register again and select **Rob Store** to grab the loot.

### Robbing a Bank
1.  **Target** the Bank Vault.
2.  Select **Blow Vault**.
3.  Plant the **Dynamite**.
4.  **RUN!** You have **5 seconds** before the blast.
5.  **Wait**: The vault is too hot. Wait **10 minutes** (default) for the smoke to clear.
6.  Once the heat dissipates, **Target** the vault again to **Loot Vault**.

## Developer Notes

*   **Global State**: The resource uses `GlobalState.devchacha_robbery_states` to track vault statuses (`blown`, `unlocking`, `open`).
*   **Security**: Server-side validation handles all cooldowns, items, and state transitions. Client-side attempts to cheat the timers will be rejected.
