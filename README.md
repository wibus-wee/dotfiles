# Wibus's Dotfiles

This is a collection of my dotfiles.

- Using `rcm` to manage the dotfiles.
- Using `Brewfile` to install the packages.

> [!NOTE]
> It will backup your development environment, and install the dotfiles.
>
> _**Quickly restore your brand new computer to your familiar development environment 😄**_

## Installation

If computer is **a brand new one**, you can use the following command to install the dotfiles:

```bash
# Generate SSH key, GPG key, or import your keys' backup create by `sign.sh`
curl -L https://raw.githubusercontent.com/wibus-wee/dotfiles/main/sign.sh | sh
```

```bash
# Install the dotfiles
curl -L https://raw.githubusercontent.com/wibus-wee/dotfiles/main/setup.sh | sh
```

> [!IMPORTANT]
> Please make sure you have a stable internet connection, and a password of your computer.

> After the installation, please restart your terminal to apply the changes.

## Update

```bash
mtr # alias of `sh ~/.mtr.sh`
```