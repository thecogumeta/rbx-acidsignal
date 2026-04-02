---
sidebar_position: 2
---

# Installation

## Method 1. Manual Installation

Download the [latest release](https://github.com/thecogumeta/acidsignal/releases/) and place it in your project (e.g., `ReplicatedStorage`).

## Method 2. Install with Wally

### 1. Add dependency

Add the package to your `wally.toml`:

```toml
[dependencies]
AcidSignal = "thecogumeta/acidsignal@1.0.0"
```

### 2. Install

```bash
wally install
```

### 3. Add Packages to your project

Make sure your `default.project.json` includes Wally packages:

```json
{
  "name": "YourProject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

## Using with roblox-ts

Install the package:

```bash
npm install @rbxts/acidsignal
```

Then import in your code:

```ts
import Signal from "@rbxts/acidsignal";

const signal = Signal.new<[string]>();

signal.Connect((value) => {
  print("fired:", value);
});

signal.Fire("hello");
```
