# Duplika

Run a second, isolated copy of an app on one device. Each clone gets its own container and
its own data, so two accounts can be signed in at once without swapping.

## Download

**[Download the latest APK](https://github.com/Istiakahmed180/app_clone/releases/download/latest-build/duplika-arm64-v8a.apk)** · [all builds](https://github.com/Istiakahmed180/app_clone/releases/tag/latest-build)

The link always points at the newest build, so it does not go stale.

Before installing, three things worth knowing:

- **arm64-v8a only.** It will not install on a 32-bit or x86 device. Nearly every phone sold
  since about 2019 is arm64.
- **Not a Play Store release.** Android will warn about installing from an unknown source,
  and you have to allow it for whichever app you download with.
- **Not an update path.** Each build is signed with a throwaway key, so a new APK will not
  install over an older one — uninstall first. **Uninstalling removes your clones.**

## Building it yourself

```sh
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Or build it on GitHub instead, which needs only the [GitHub CLI](https://cli.github.com):

```sh
./scripts/build-apk.sh            # build it; downloading needs a GitHub login
./scripts/build-apk.sh --public   # also refresh the download link above
```

Nothing is built on an ordinary push — the script, or the **Build APK** workflow in the
Actions tab, is the trigger. See [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml).

## Notes

- Apps the engine cannot host are left out of the picker rather than offered and then
  refused, so what you can see is what you can clone.
- Some apps ask not to be run inside a container. Duplika treats that as binding and will
  not clone them.
- Google features that verify an app's own identity — sign-in, push — do not work inside a
  clone. A clone is a second install, not a second device.
