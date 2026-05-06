console.log("🚀 Node.js tesztek indítása...");

// Olvassuk be a titkot a környezeti változóból!
// A változó neve SAJAT_TITKUNK lesz, ezt a Jenkinsből fogjuk beküldeni.
const apiKey = process.env.SAJAT_TITKUNK;

if (apiKey === "EZ-EGY-HIBAS-KULCS") {
    console.log("✅ SIKERES TESZT: A Jenkins sikeresen és titkosítva átadta az API kulcsot!");
    console.log("A kapott kulcs (amit a Jenkins el fog rejteni): " + apiKey);
    process.exit(0);
} else {
    console.log("❌ HIBÁS TESZT: Nem kaptam meg a titkos kulcsot, vagy hibás az értéke!");
    console.log("Ezt kaptam helyette: " + apiKey);
    process.exit(1);
}
