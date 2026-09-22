# WelcomeXP innloggingsskjerm — installasjon

Les RECOVERY.md FØRST. Kjør kommandoene én blokk om gangen.
Repoene er allerede klonet i denne mappa.

## Steg 1 — byggeverktøy

    sudo apt install -y build-essential libgirepository1.0-dev \
      liblightdm-gobject-1-0 liblightdm-gobject-1-dev libcairo2-dev

## Steg 2 — bygg nody-greeter med Node 18

Node 22 fra nvm ligger først i PATH. nody-greeter krever 18.x,
som allerede er installert i /usr/bin. Derfor settes PATH eksplisitt:

    cd ~/xp-login-setup/nody-greeter
    export PATH=/usr/bin:$PATH
    node --version      # skal si v18.19.1
    npm install
    npm run rebuild
    npm run build
    sudo /usr/bin/node make install

## Steg 3 — la Cinnamon-sesjonen brukes av greeteren

    sudo sh -c 'grep -q X-LightDM-Allow-Greeter /usr/share/xsessions/cinnamon.desktop \
      || echo "X-LightDM-Allow-Greeter=true" >> /usr/share/xsessions/cinnamon.desktop'

## Steg 4 — installer temaet

    cd ~/xp-login-setup
    sudo cp -R WelcomeXP /usr/share/web-greeter/themes/
    sudo chmod -R 755 /usr/share/web-greeter/themes/WelcomeXP
    sudo sed -i 's/^\( *theme:\).*/\1 WelcomeXP/' /etc/lightdm/web-greeter.yml
    grep -n 'theme:' /etc/lightdm/web-greeter.yml

## Steg 5 — TEST FØR DU BYTTER (viktig)

    nody-greeter --debug

Et vindu med XP-innloggingsskjermen skal dukke opp.
Ser du den uten feil: gå videre. Ser du den ikke: STOPP, ikke gjør steg 6.

## Steg 6 — bytt greeter

    sudo sh -c 'printf "[Seat:*]\ngreeter-session=nody-greeter\nuser-session=cinnamon\n" > /etc/lightdm/lightdm.conf.d/99-nody.conf'
    cat /etc/lightdm/lightdm.conf.d/99-nody.conf
    sudo systemctl restart lightdm

Egen fil brukes med vilje — da kan den slettes for å angre alt.

## Steg 7 — se den

Du har autologin på, så du ser den ikke ved oppstart.
Meny -> Logg ut, eller Bytt bruker.

## Valgfritt — ekte XP-fonter

Temaet vil ha tahoma.ttf, tahomabd.ttf og FRADMIT.TTF i
en fonts/-mappe inni temaet. Har du en Windows-installasjon,
finnes de i C:\Windows\Fonts. Uten dem brukes fallback-fonter.

    sudo mkdir -p /usr/share/web-greeter/themes/WelcomeXP/fonts
    sudo cp tahoma.ttf tahomabd.ttf FRADMIT.TTF \
      /usr/share/web-greeter/themes/WelcomeXP/fonts/
    sudo chmod -R 755 /usr/share/web-greeter/themes/WelcomeXP/fonts

---

# Feilsøking: "Cannot find module 'yargs'"

Årsak: under `npm run build` feilet steget
`Installing packages with 'npm ci --production -s'` (trolig timeout mot
npm-registry). build.js fanger feilen i en try/catch og skriver "SUCCESS!"
likevel, så asar-pakken ble laget uten runtime-avhengigheter.

## Fiks

    cd ~/xp-login-setup/nody-greeter
    export PATH=/usr/bin:$PATH
    npm run build
    sudo /usr/bin/node make install

Se etter linja `Packages installed` i utskriften. Står det `Error: Command
failed: npm ci` i stedet, har det feilet igjen — kjør `npm run build` på nytt.

## Verifiser før du tester

    npx asar list /opt/nody-greeter/resources/app.asar | grep -c node_modules/yargs

Skal gi et tall større enn 0. Gir den 0, er pakken fortsatt ufullstendig.

## Så test

    nody-greeter --debug

