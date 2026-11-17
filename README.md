# CyberNeon — tema "netrunner" per KDE Plasma 6 (X11 e Wayland)

> ## ⚠ Fan made — tutto il merito a CD PROJEKT RED
> **CyberNeon è un progetto FAN MADE, realizzato da un grandissimo fan di _Cyberpunk 2077_ e di CD PROJEKT RED.**
> È **ispirato a _Cyberpunk 2077_ di CD PROJEKT RED**: l'universo, lo stile e l'atmosfera a cui si ispira sono **opera di CD PROJEKT RED**.
> _Cyberpunk 2077_, Arasaka e tutti i nomi, i loghi e i marchi collegati **appartengono a CD PROJEKT S.A.**
> Progetto **non ufficiale** e **non commerciale**: non è affiliato, sponsorizzato né approvato da CD PROJEKT RED.
> L'unico elemento di CD PROJEKT RED incluso è il **logo Arasaka** (`assets/logo/`), usato come omaggio fan made: resta di CD PROJEKT S.A. (vedi [Crediti](#crediti-marchi-e-licenze) e [`NOTICE.md`](NOTICE.md)).

![CyberNeon per KDE Plasma 6](docs/kde-desktop.png)

<sub>Screenshot reale di Plasma 6.8 (laboratorio Docker incluso nel repo: <a href="#laboratorio-test-senza-un-pc-kde">vedi sotto</a>).
Nel laboratorio l'utente si chiama "netrunner": sul tuo PC la targhetta dell'HUD mostra il tuo nome.</sub>

Questa è l'edizione **KDE Plasma 6** di CyberNeon, per **Wayland** e **X11**: blu notte, cornici rosso neon con taglio a 45°,
testi e icone ciano, dock con barra rossa che incrocia la linea neon della barra in alto, HUD, orologio e uno **sfondo animato**.
Rispetto all'edizione Budgie (repository separato) sfrutta quello che Plasma permette in più: cornici delle finestre in QML,
widget Qt con angoli tagliati (Kvantum), popup in vetro sfocato, splash di avvio e un effetto glitch sulle finestre.

> **Stato**: provata su **Plasma 6.8.3** (Arch Linux) nel laboratorio Docker del repo, con screenshot reali di ogni parte.
> Su altre distribuzioni con Plasma 6 dovrebbe comportarsi allo stesso modo; se qualcosa non torna, vedi
> [Primo avvio e verifica](#primo-avvio-e-verifica).

| | |
|---|---|
| ![Finestre](docs/kde-windows.png) **Cornici QML + widget Kvantum** (Dolphin in primo piano, Konsole dietro) | ![Splash](docs/kde-splash.png) **Splash di avvio "jack-in"** |
| ![Login](docs/kde-sddm.png) **Login SDDM** (modalità prova, quindi senza sfondo) | ![Prompt](docs/prompt.png) **Prompt bash** |

---

## Indice

- [Cosa include](#cosa-include)
- [Requisiti](#requisiti)
- [Installazione](#installazione)
- [Configurazione (`cyberneon.conf`)](#configurazione-cyberneonconf)
- [Cosa fa `install.sh`](#cosa-fa-installsh)
- [Schermata di login (SDDM) e GRUB](#schermata-di-login-sddm-e-grub)
- [Primo avvio e verifica](#primo-avvio-e-verifica)
- [Laboratorio: test senza un PC KDE](#laboratorio-test-senza-un-pc-kde)
- [Disinstallazione](#disinstallazione)
- [Struttura del repository](#struttura-del-repository)
- [Personalizzazione](#personalizzazione)
- [Note tecniche](#note-tecniche)
- [Crediti, marchi e licenze](#crediti-marchi-e-licenze)

---

## Cosa include

| Componente | Descrizione |
|---|---|
| **Cornici delle finestre (QML)** | Decorazione KWin `CyberNeon` scritta in QML: cornice rosso neon con **taglio grande a 45°** in alto a sinistra e uno piccolo in basso a destra, linea interna chiara come un tubo al neon, tre quadratini HUD e titolo maiuscolo spaziato, pulsanti con l'angolo tagliato (pieni al passaggio del mouse, X rossa sulla chiusura), segmento ciano "di stato" sul bordo inferiore. Finestre inattive in rosso scuro. In alternativa c'è una versione SVG più semplice (`DECORATION="svg"`). |
| **Widget Qt (Kvantum)** | Tema Kvantum `CyberNeon`: pulsanti, campi, combo e schede con **angoli tagliati** e contorno ciano, barre degli strumenti blu con riga ciano, menu blu semitrasparenti con bordo rosso e sfocatura, tooltip ciano, barre di progresso **a strisce diagonali**, caselle quadrate e pulsanti di opzione **a rombo**. |
| **Tema desktop Plasma** | Barra in alto con linea neon (nucleo chiaro e alone), dock con barra rossa; popup, menu e notifiche con **angoli tagliati** e vetro sfocato (le maschere della sfocatura seguono la forma); pulsanti del task manager con l'evidenziazione ciano e la tacca a sinistra. |
| **Layout** | Barra in alto a tutta larghezza che passa sopra la dock (**la linea neon incrocia la barra rossa**, blocco rosso 76–110 px sopra la linea), dock a sinistra (90 px) con Kickoff col logo CyberNeon, icone cerchiate e pager; nella barra il lanciatore col logo (Application Dashboard), area di notifica, orologio `AAAA-MM-GG  HH:MM`, blocco/uscita. |
| **Sfondo animato** | Plugin `CyberNeon Live`: lo sfondo CyberNeon con **linea di scansione**, **archi che ruotano** attorno al sigillo, **nodi del grafo che lampeggiano** e bersaglio che pulsa, **pacchetti di dati** lungo il percorso evidenziato, **colonne esadecimali** che scendono e **glitch** periodici. Disattivabile (`ANIMATED_WALLPAPER="no"`). |
| **Splash di avvio** | Sequenza "**// JACKING IN**": logo che si accende con un flicker, barra di avanzamento a strisce, righe di stato a ogni fase, staffe rosse agli angoli. |
| **Effetto glitch** | Effetto KWin: le finestre si aprono e si chiudono con un **flicker neon** e uno scatto laterale (sostituisce l'animazione "scale"). Disattivabile (`GLITCH_EFFECT="no"`). |
| **Tema globale** | Pacchetto *Look and Feel* `CyberNeon`, selezionabile in *Impostazioni di sistema → Tema globale*. |
| **Widget HUD e orologio** | `CyberNeon HUD` (CPU, RAM e disco con i sensori di Plasma, blocco a strisce, targhetta verticale) e `CyberNeon Clock` (ora ciano in Orbitron, data rossa). Funzionano su Wayland. |
| **Icone, cursori, font, sfondo, prompt** | Come nell'edizione Budgie: icone cerchiate originali + Papirus-Dark con cartelle "cyber", cursori HUD con bagliore, Chakra Petch/Rajdhani/Orbitron, prompt bash rosso/ciano. |
| **Konsole, Dolphin, app GTK** | Profilo Konsole `CyberNeon`; Dolphin trasparente al 90 % (regola KWin); tema GTK `CyberNeon` per le app GTK. |
| **Blocco schermo, login, GRUB** | Blocco schermo con lo sfondo di login; tema SDDM `cyberneon`; tema GRUB. |

## Requisiti

- **KDE Plasma 6** (KDE neon, Kubuntu, Fedora KDE, Arch, openSUSE…), sessione **Wayland** o **X11**.
- `python3` con **Pillow** e **pycairo**, `curl`; consigliati **kvantum** (widget Qt in stile HUD), **kdeplasma-addons**
  (Application Dashboard per il lanciatore col logo) e **JetBrainsMono Nerd Font** (prompt e sfondo).

  ```bash
  sudo apt install python3-pil python3-cairo curl qt6-style-kvantum kdeplasma-addons-data   # Debian/Ubuntu/Kubuntu/neon
  sudo dnf install python3-pillow python3-cairo curl kvantum kdeplasma-addons               # Fedora
  sudo pacman -S python-pillow python-cairo curl kvantum kdeplasma-addons                   # Arch
  ```
  (i nomi dei pacchetti Kvantum e addons cambiano un po' tra distribuzioni: se uno non esiste, cerca "kvantum" /
  "kdeplasma-addons" nel gestore pacchetti). Senza Kvantum le app Qt usano Breeze con i colori CyberNeon; senza
  kdeplasma-addons il lanciatore col logo usa Kicker o Kickoff.
- Per il tema GRUB: `grub-mkfont` (o `grub2-mkfont`). Prima installazione: Internet per Papirus (~33 MB).

## Installazione

```bash
git clone <url-di-questo-repo> cyberneon-kde
cd cyberneon-kde
./install.sh
```

| Opzione | Effetto |
|---|---|
| `--no-layout` | non tocca pannelli e widget (applica temi, colori, icone, cursori, font, cornici, Kvantum, Konsole, Dolphin, prompt) |
| `--skip-papirus` | non scarica Papirus |
| `-h` | aiuto |

> ⚠ Senza `--no-layout` i pannelli attuali vengono sostituiti dalla barra e dalla dock CyberNeon (la configurazione
> precedente è nel backup: `uninstall.sh` la ripristina). Dopo l'installazione conviene fare **logout e login**.

## Configurazione (`cyberneon.conf`)

| Variabile | Default | Significato |
|---|---|---|
| `LOGO` | `assets/logo/arasaka-logo.webp` | logo al centro dello sfondo, sul lanciatore della barra e nella splash (tinto rosso neon). Il logo Arasaka incluso è di CD PROJEKT S.A.; vuoto = stemma originale CyberNeon |
| `LABEL` | `A R A S A K A` | scritta sotto lo stemma dello sfondo |
| `HUD_LABEL` | *(vuoto)* | targhetta del widget HUD; vuoto = nome utente in maiuscolo |
| `WALLPAPER` | `cyberneon-arasaka-red.png` | file creato in `~/Pictures/Wallpapers` |
| `DECORATION` | `qml` | cornici delle finestre: `qml` (taglio grande, dettagli HUD) o `svg` (Aurorae SVG, più semplice) |
| `ANIMATED_WALLPAPER` | `yes` | sfondo animato `CyberNeon Live` o immagine statica (`no`) |
| `GLITCH_EFFECT` | `yes` | effetto glitch su apertura/chiusura delle finestre |
| `DOLPHIN_OPACITY` | `90` | opacità di Dolphin in percentuale |
| `PINNED` | impostazioni, file manager, browser, Konsole, LibreOffice Calc | lanciatori della dock (sintassi di Plasma) |
| `UI_FONT`, `FIXED_FONT`, `TITLE_FONT` | Chakra Petch 10 / JetBrainsMono Nerd Font 10 / Chakra Petch Bold 10 | font |

## Cosa fa `install.sh`

1. **Controlli** (Plasma 6, strumenti, Python) e larghezza logica dello schermo principale (`kscreen-doctor`).
2. **Backup** in `~/.local/share/cyberneon/backups/<data-ora>/` di `kdeglobals`, `kwinrc`, `kwinrulesrc`, `plasmarc`,
   `plasmashellrc`, `plasma-org.kde.plasma.desktop-appletsrc`, `kcminputrc`, `konsolerc`, `ksplashrc`, `kscreenlockerrc`,
   impostazioni GTK, `Kvantum/kvantum.kvconfig` e `~/.bashrc` (la prima volta anche in `backups/pristine/`).
3. **Font**, **Papirus**, **tema GTK** (da `third_party/Pocillo-dark`) e palette libadwaita.
4. **Icone** `CyberNeon-Icons` (con il logo tinto e l'icona `cyberneon-launcher`) e **cursori** `CyberNeon-Cursors`.
5. **Sfondo** e asset di login/GRUB.
6. **Temi KDE**: schema colori, tema desktop Plasma (con popup in vetro), cornici SVG Aurorae, **cornici QML**
   (copiate in `~/.local/share/kwin/decorations/`), font e decorazione in `kdeglobals`/`kwinrc`.
7. **Kvantum** (se installato): tema in `~/.config/Kvantum/CyberNeon`, `widgetStyle=kvantum`.
8. **Sfondo animato**, **tema globale + splash**, **blocco schermo**, **effetto glitch** (caricato subito via D-Bus).
9. **Regola KWin** per Dolphin, **Konsole**, impostazioni **GTK**, **prompt** bash.
10. **Widget** HUD, orologio e blocco rosso (`kpackagetool6`).
11. **Layout** (`kde/layout.js`): barra, dock, lanciatori, sfondo, HUD e orologio; pannelli opachi.
12. **Ricarica** di KWin e riavvio di plasmashell.

## Schermata di login (SDDM) e GRUB

```bash
sddm-greeter-qt6 --test-mode --theme kde/sddm/cyberneon   # anteprima senza cambiare niente
sudo bash system/install-sddm.sh                          # tema SDDM
sudo bash system/install-grub.sh                          # tema GRUB (menu visibile 5 secondi)
```

`install-sddm.sh` copia il tema in `/usr/share/sddm/themes/cyberneon` con lo sfondo di login, cursori e font, e scrive
`/etc/sddm.conf.d/10-cyberneon.conf` (annulla: `sudo rm /etc/sddm.conf.d/10-cyberneon.conf`).
`install-grub.sh` installa il tema in `/boot/grub/themes/cyberneon`, imposta `GRUB_THEME`, `GRUB_TIMEOUT_STYLE=menu`,
`GRUB_TIMEOUT=5` e lancia `update-grub` (su Fedora/openSUSE poi `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`).
Annulla: `sudo cp /etc/default/grub.bak-cyberneon /etc/default/grub` e rigenera la configurazione.

## Primo avvio e verifica

1. `./install.sh` termina e `layout.js` stampa `panels <id> <id>`;
2. cornici: taglio a 45° grande, tre quadratini, titolo maiuscolo, pulsanti dentro la barra del titolo;
3. pannelli: la linea neon della barra in alto incrocia la barra rossa della dock, blocco rosso e raccordo nell'angolo;
4. sfondo animato in movimento, HUD con valori che si aggiornano, orologio in alto a destra;
5. app Qt (Dolphin, Impostazioni) con pulsanti ad angoli tagliati (serve Kvantum);
6. apri e chiudi una finestra: flicker glitch;
7. login SDDM in `--test-mode`.

Errori dei widget e delle cornici: `journalctl --user -b | grep -iE "cyberneon|qml"`.

## Laboratorio: test senza un PC KDE

`lab/` contiene un ambiente Docker con **Arch Linux + Plasma 6** che gira senza schermo (KWin in modalità virtuale con
OpenGL sul nodo di rendering della GPU del PC). Esegue il vero `install.sh` e salva screenshot reali in `lab/out/`:

```bash
bash lab/run-lab.sh     # serve Docker (utente nel gruppo docker); la prima volta scarica ~2 GB
```

Produce `01-plasma-stock.png` (Plasma di partenza), `02-cyberneon-desktop.png` e `02b-…` (due istanti dello sfondo
animato), `03-cyberneon-windows.png` (Dolphin e Konsole), `05-splash.png`, `06-launcher-menu.png`, `04-sddm-test.png`,
più `install.log`, `qmllint.txt` ed `effects.txt` (verifica che l'effetto glitch sia caricato). Il tuo sistema non viene toccato.

## Disinstallazione

```bash
./uninstall.sh          # ripristina la configurazione KDE/GTK di prima e rimuove i file CyberNeon
./uninstall.sh --purge  # rimuove anche i font CyberNeon e Papirus
```

## Struttura del repository

```
cyberneon-kde/
├── install.sh / uninstall.sh      installazione e ripristino
├── cyberneon.conf                 configurazione
├── kde/
│   ├── layout.js                  pannelli, lanciatori, sfondo, widget (Plasma scripting)
│   ├── decoration/cyberneon/      cornici delle finestre in QML (KWin)
│   ├── wallpaper/                 sfondo animato "CyberNeon Live" (QML)
│   ├── lookandfeel/               tema globale + splash "jack-in"
│   ├── effects/cyberneon_glitch/  effetto glitch apertura/chiusura (KWin, JavaScript)
│   ├── plasmoids/                 widget HUD, orologio, blocco rosso (QML)
│   ├── konsole/                   palette e profilo Konsole
│   └── sddm/cyberneon/            tema SDDM (Qt 6)
├── scripts/
│   ├── make_kde_themes.py         cornici SVG Aurorae + tema desktop Plasma + schema colori
│   ├── make_kvantum.py            tema Kvantum (widget Qt)
│   ├── build_theme.py             tema GTK
│   ├── make_icons.py, make_logo_icon.py, make_cursors.py, make_wallpaper.py, make_system_assets.py
│   └── install_fonts.sh, install_papirus.sh
├── lab/                           laboratorio Docker (Dockerfile, run-lab.sh, inside.sh)
├── theme/, config/, system/       CSS GTK, prompt, SDDM/GRUB
├── third_party/Pocillo-dark/      base del tema GTK (GPL-2.0)
├── assets/fonts, assets/logo      font (OFL) e logo Arasaka (© CD PROJEKT S.A.)
└── docs/                          screenshot
```

## Personalizzazione

- **Palette**: rosso neon `#ff2a4f`, ciano `#5beedc`, blu `#111e29` — costanti in testa a `make_kde_themes.py`,
  `make_kvantum.py`, ai file QML e ai CSS GTK.
- **Cornici QML**: `titleH`, `cut`, `brCut`, bordi e colori in testa a `kde/decoration/cyberneon/contents/ui/main.qml`.
- **Sfondo animato**: velocità e oggetti in `kde/wallpaper/org.cyberneon.wallpaper/contents/ui/main.qml`
  (coordinate dello sfondo 3840×2160).
- **Effetto glitch**: durate in `kde/effects/cyberneon_glitch/contents/code/main.js`.
- **Dock e barra**: `DOCK` e `BAR` in `kde/layout.js`; margini delle icone in `tasks_svg()` di `make_kde_themes.py`.

## Note tecniche

Cose verificate nel laboratorio:
- **Ordine dei pannelli**: Plasma calcola posizione e offset di un pannello rispetto a quelli creati prima. La barra in alto
  viene creata **prima** della dock, così è larga tutto lo schermo e la dock parte sotto (come su Budgie).
- Il bordo di un pannello che tocca un altro pannello viene disattivato: il blocco rosso 76–110 px è un piccolo widget
  (`org.cyberneon.redblock`) che si posiziona in coordinate di schermo.
- Le icone del task manager sono centrate sullo spessore della dock: la loro dimensione si regola con i margini di
  `widgets/tasks.svg`. Le ombre del tema sui pannelli opachi non vengono disegnate, quindi la barra rossa resta dentro la dock.
- `kpackagetool6` rifiuta i pacchetti `KWin/Decoration` (anche quello ufficiale *plastik*): la decorazione QML viene
  **copiata** in `~/.local/share/kwin/decorations/`, dove KWin la trova.
- Gli effetti KWin copiati con KWin già avviato si caricano al login successivo: l'installer li carica subito via D-Bus.
- L'*Application Dashboard* su Plasma 6 sta in `kdeplasma-addons`; `layout.js` ripiega su Kicker/Kickoff.
- Le coordinate dei widget sul desktop sono relative all'area libera dai pannelli.
- Nel `Canvas` QML i font si indicano senza virgolette singole (`"bold 15px \"Chakra Petch\""`).

## Crediti, marchi e licenze

**CD PROJEKT RED / _Cyberpunk 2077_: fan made, con tutto il rispetto**
- CyberNeon è un progetto **FAN MADE**, realizzato da **un grandissimo fan di _Cyberpunk 2077_ e di CD PROJEKT RED**, come
  omaggio al loro lavoro.
- È **ispirato a _Cyberpunk 2077_ di CD PROJEKT RED**: l'immaginario netrunner, i colori rosso/ciano, le interfacce angolari e
  l'atmosfera sono **creazioni di CD PROJEKT RED**.
- *Cyberpunk 2077*, *Arasaka*, *Night City* e tutti i nomi, loghi e marchi collegati sono **marchi registrati e/o opere protette di
  CD PROJEKT S.A.** e appartengono a loro.
- Progetto **non ufficiale**: **non è affiliato, sponsorizzato né approvato** da CD PROJEKT RED o CD PROJEKT S.A.
- Sfondo, icone, cursori, stemma, widget e cornici sono **disegnati da zero via codice**. L'unico elemento di CD PROJEKT RED
  incluso è il **logo Arasaka** (`assets/logo/arasaka-logo.webp`), insieme al nome in `LABEL`: sono **di CD PROJEKT S.A.**, usati
  come omaggio fan made e non coperti dalla licenza del repository (vedi le
  [linee guida per i contenuti dei fan di CD PROJEKT RED](https://www.cdprojektred.com/en/fan-content)).
- Uso **esclusivamente non commerciale**. Se ti piace questo tema, gioca e supporta *Cyberpunk 2077* di CD PROJEKT RED.
- Se CD PROJEKT RED chiede modifiche o la rimozione di qualcosa, verrà fatto subito.

**Componenti di terze parti**
- **Pocillo-dark** (Ubuntu Budgie, pacchetto `ubuntu-budgie-themes` 0.19.0, GPL-2.0): incluso in `third_party/` con licenza e
  copyright; il tema GTK generato è un'opera derivata GPL-2.0.
- **Papirus icon theme** (GPL-3.0): scaricato durante l'installazione, non incluso.
- **Chakra Petch**, **Rajdhani**, **Orbitron**: SIL Open Font License 1.1, inclusi con le licenze.
- **KDE Plasma**, **KWin/Aurorae**, **Konsole**, **Dolphin**, **SDDM**: usati, non modificati.

**Licenza di questo repository**: GPL-2.0 (vedi `LICENSE`), salvo i componenti di terze parti e i marchi indicati sopra.

---

<sub><b>Fan made</b> da un grandissimo fan di <i>Cyberpunk 2077</i>. CyberNeon è un progetto non ufficiale e non commerciale,
ispirato a <i>Cyberpunk 2077</i> di <b>CD PROJEKT RED</b>. <i>Cyberpunk 2077</i>, Arasaka e tutti i nomi, loghi e marchi collegati
appartengono a <b>CD PROJEKT S.A.</b> Questo progetto non è affiliato, sponsorizzato né approvato da CD PROJEKT RED.</sub>
