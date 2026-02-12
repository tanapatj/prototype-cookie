# Contributing Guide

Thank you for your interest in contributing to this project!

## Getting Started

### Prerequisites

1. You need to have [Node.js LTS](https://nodejs.org/en/download/) installed.
2. This project uses `pnpm` to manage dependencies:
    ```bash
    npm i -g pnpm
    ```

### Making Changes

1. Clone the repository and create a new branch for your work.

2. Install all dependencies:
    ```
    pnpm install
    ```

3. Make changes. To see your local changes in action, run:
    ```
    pnpm dev
    ```

4. Generate the bundled version:
    ```
    pnpm build
    ```

5. Make sure tests pass:
    ```
    pnpm test
    ```

6. Push the changes and create a Pull Request.

### Pull Requests

1. When creating a PR, briefly explain what it improves or fixes.
2. Link any related issues.
3. Enable the "allow maintainer edits" checkbox.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
