# Kom deg inn på PC-en hvis innloggingsskjermen ryker

## Situasjon 1: Svart skjerm / ingen innlogging etter omstart

1. Trykk `Ctrl` + `Alt` + `F2`  (prøv F3/F4/F5 hvis F2 ikke gir noe)
2. Du får en tekstbasert innlogging. Skriv brukernavn `noa`, trykk Enter, skriv passord, Enter.
   (Passordet vises IKKE mens du skriver — det er normalt.)
3. Sett tilbake gammel innloggingsskjerm:

       sudo sed -i 's/^greeter-session=.*/greeter-session=slick-greeter/' /etc/lightdm/lightdm.conf.d/99-nody.conf

   Eller enda enklere — slett hele fila:

       sudo rm -f /etc/lightdm/lightdm.conf.d/99-nody.conf

4. Start innloggingstjenesten på nytt:

       sudo systemctl restart lightdm

5. Du skal nå få vanlig Mint-innlogging tilbake.

## Situasjon 2: Kommer ikke til TTY heller

1. Start PC-en på nytt. Hold `Shift` under oppstart for å få GRUB-menyen.
2. Velg `Advanced options for Linux Mint` -> en linje som slutter på `(recovery mode)`
3. Velg `root - Drop to root shell prompt`
4. Gjør filsystemet skrivbart:

       mount -o remount,rw /

5. Kjør:

       rm -f /etc/lightdm/lightdm.conf.d/99-nody.conf
       reboot

## Situasjon 3: Innlogging virker, men skjermen henger etter innlogging

Logg inn via `Ctrl` + `Alt` + `F2` som i situasjon 1, og kjør:

    sudo systemctl restart lightdm

## Bra nyhet: du har autologin på

/etc/lightdm/lightdm.conf har `autologin-user=noa`.
Det betyr at PC-en logger deg inn automatisk ved oppstart uten aa vise
innloggingsskjermen i det hele tatt. En oedelagt greeter vil derfor
normalt IKKE laase deg ute ved vanlig oppstart.

Du ser den nye innloggingsskjermen kun ved:
  - Logg ut
  - Bytt bruker

## Angre alt

    sudo rm -f /etc/lightdm/lightdm.conf.d/99-nody.conf
    sudo rm -rf /usr/share/web-greeter/themes/WelcomeXP
    sudo systemctl restart lightdm
