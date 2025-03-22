# LUIS: Love UI System - SAMPLES

<p align="center">
 <a href="https://github.com/SiENcE/luis/blob/main/assets/logo_small.png">
  <img border="0" src="https://github.com/SiENcE/luis/blob/main/assets/logo_small.png">
 </a>
</p>

**LUIS** (Love User Interface System) is a flexible graphical user interface (GUI) framework built on top of the [Löve2D](https://love2d.org/) game framework. LUIS provides developers with the tools to create dynamic, grid-centric, layered user interfaces for games and applications.

## LUIS: Samples

<p align="center">
 <a href="https://github.com/SiENcE/luis/blob/main/assets/screenshots/Screenshot_2024-12-17.jpg">
  <img border="0" style="max-width:100%; height:auto;" src="https://github.com/SiENcE/luis/blob/main/assets/screenshots/Screenshot_2024-12-17.jpg">
 </a>
</p>
<p align="center">
 <em>Flexible Layout using FlexContainer with a couple of widgets.</em>
</p>

<p align="center">
 <a href="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-12-17_14.59.55.gif">
  <img border="0" style="max-width:100%; height:auto;" src="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-12-17_14.59.55.gif">
 </a>
</p>
<p align="center">
 <em>You can see different layers, a custom widget within a Flex container, theming, and a variety of available widgets.</em>
</p>

<p align="center">
 <a href="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-12-17_14.49.44.gif">
  <img border="0" style="max-width:100%; height:auto;" src="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-12-17_14.49.44.gif">
 </a>
</p>
<p align="center">
 <em>Virtual gamepad integration made with LUIS.</em>
</p>

<p align="center">
 <a href="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-11-12_00.58.43.gif">
  <img border="0" style="max-width:100%; height:auto;" src="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-11-12_00.58.43.gif">
 </a>
</p>
<p align="center">
 <em>A LUIS UI-Editor made with LUIS.</em>
</p>

<p align="center">
 <a href="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-12-17_14.53.47.gif">
  <img border="0" style="max-width:100%; height:auto;" src="https://github.com/SiENcE/luis/blob/main/assets/recordings/Recording_2024-12-17_14.53.47.gif">
 </a>
</p>
<p align="center">
 <em>1-bit full adder node graph - created with LUIS Node Widgets.</em>
</p>

## Getting Started

1. **Install Löve2D** (11.5): You can download Löve2D 11.5 from [here](https://love2d.org/).
2. **Clone the LUIS Library**:
    ```bash
    git clone --recurse-submodules https://github.com/SiENcE/luis_samples.git
    ```
3. **Start the samples**:
    ```lua
    love luis_samples/
    ```

4. **Switch samples**:
    Edit main.lua to switch look at different samples.

## Features

| Feature | Description |
|---------|-------------|
| Flexible Layout | Uses a grid-based system and FlexContainers for easy UI layout |
| Layer Management | Support for multiple UI layers with show/hide functionality & Z-indexing for element layering |
| Theme Support | Global theme customization, Per-widget theme overrides |
| Customizable Theming | Easily change the look and feel of your UI elements |
| Widget API | Core system for loading and managing widgets (widgets themselves are optional and loaded dynamically) |
| Event Handling | Built-in support for mouse, touch, keyboard, and gamepad interactions & focus management |
| Responsive Design | Automatically scales UI elements and interaction based on screen dimensions |
| State Management | Tracks and persists element states to save and load configurations |
| Extensibility | Modular design allowing easy addition of new widgets or removing unneeded widgets (see Widget Types section) |
| Debug Mode | Toggle grid and element outlines for easy development |


**Note**: These features are all part of the [LUIS core library](https://github.com/SiENcE/luis/tree/restructuring) (`core.lua`), which has **zero dependencies**! You can use the core library on its own and implement your own widgets for a lightweight UI system for [Löve2D](https://love2d.org/) without any additional dependencies.

## Documentation

For more detailed information on the LUIS API, including layer management, input handling, theming, and state management, please refer to the [LUIS core documentation](https://github.com/SiENcE/luis/blob/restructuring/luis-api-documentation.md).

## Dependencies

- Löve2D: The game framework used for rendering and managing game objects.
- The **core** library has **zero dependencies**, so you write your own widgets to have a lightweight ui system (see [basic_ui_sample](/samples/basic_ui/) ).

## known Problems

- DropBox: Selection with the gamepad-analogstick works not for all choices
- FlexContainer - dropdown select is not possible via gamepad-analogstick
- TextInput - when changing Theme, we have to adjust the fontsize in TextInput widgets
- TextInputMultiLine doesn't support setConfig/getConfig

## License

This project is licensed under the MIT License with additional terms - see the [LICENSE](LICENSE) file for details.
**Important:** Use of this software for training AI or machine learning models is strictly prohibited. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
