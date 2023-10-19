# Package

version       = "0.1.0"
author        = "kerorinnf"
description   = "Souzou seisaku web app"
license       = "MIT"
srcDir        = "src"
bin           = @["app"]


# Dependencies

requires "nim >= 2.0.0"
requires "prologue >= 0.6.4"
requires "norm >= 2.8.1"

import os, strformat

# Appをビルドするタスク
task buildApp, "Build the application.":
  let
    build_path = "./build"
    app_path = "./src" / "app"
    env_path = "./src" / ".env"
    key_path = "./src" / "key"
  mkdir(build_path)
  exec &"nim c --hints:off {app_path}.nim"
  mvFile(app_path, build_path / "app")
  cpFile(env_path, build_path / ".env")
  cpDir(key_path, build_path / "key")

# Testをビルドするタスク
task buildTest, "Build the test.":
  let
    file = commandLineParams()[^1]
    build_path = "./tests" / "build"
    app_path = "./tests" / file

  if not fileExists(app_path & ".nim"):
    echo "[FAILED]:No such file."
    return

  mkdir(build_path)
  cpDir("./src/key", build_path / "key")
  exec &"nim c {app_path}.nim"
  mvFile(app_path, build_path / file)
  exec &"./{build_path}/{file}"



