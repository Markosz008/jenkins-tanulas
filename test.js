console.log("🚀 Node.js tesztek indítása...");

const a = 5;
const b = 10;

if (a + b === 15) {
    console.log("✅ SIKERES TESZT: A matematika még mindig működik! (5 + 10 = 15)");
    process.exit(0); // A 0 kilépési kód jelenti a Jenkinsnek, hogy minden rendben
} else {
    console.log("❌ HIBÁS TESZT: Valami nagyon elromlott!");
    process.exit(1); // Az 1-es kilépési kód jelenti a hibát, ez megállítja a Pipeline-t
}
