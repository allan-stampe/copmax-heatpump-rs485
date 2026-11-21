// Boks til varmepumpe-rs485 (print 66 x 54 mm) - INGEN RJ45
// Print-koordinater (x, y) fra KiCad; y=0 er kanten med USB-C, y=54 er kanten med skrueklemmer.
// Eksempel: render("bund") eller render("laag") - skift 'del' nedenfor.
del = "begge";          // "bund", "laag" eller "begge"

pcb_x = 66;  pcb_y = 54;  pcb_t = 1.6;
vaeg = 2;    luft = 1;                  // vaegtykkelse, luft rundt om print
stand_h = 5;                            // afstand print over bund
hul_d = 3.2;                            // M3 huller i print
insert_d = 4.0;                         // hul til M3 messing-insert (maal din insert: hul = ydre diameter - ca. 0.5-0.6)
insert_len = 5.7;                       // laengde paa insert
pad = 7;                                // ekstra plads i hver ende (x) til hjoernesoejler til laaget
post_d = 7;                             // diameter paa hjoernesoejler
komp_h = 14;                            // hoejde over print (klemmer, ESP32)
bund_t = 2;  laag_t = 2;

// SMA-boesning (bulkhead) til ESP32-WROOM-32UE's U.FL-pigtail, i endevaeggen ved x=0 (antenne-enden af modulet)
sma_hul_d = 6.5;                        // gevind 1/4"-36 = 6.35 mm; 6.5 giver lidt luft
sma_flad = 0;                           // >0 = D-hul: afstand fra centrum til flad side (fx 2.9 for 5.8 mm D-flade), 0 = rundt hul
sma_y = 21;                             // print-y for hullets centrum (midt for ESP32-modulet)
sma_z_over_print = 6.5;                 // hullets centrum over printets overside (moetrik 8 mm skal kunne drejes)

ind_x = pcb_x + 2*luft + 2*pad;
ind_y = pcb_y + 2*luft;
ind_h = stand_h + pcb_t + komp_h;
ud_x = ind_x + 2*vaeg;
ud_y = ind_y + 2*vaeg;

hullet = [[3.5,3.5],[62.5,3.5],[3.5,50.5],[62.5,50.5]];

// Hjoernesoejler til laag (uden for printet, i hver ende) - centrum i boks-koordinater
soejle_ind = 0.5;                       // soejlen gaar lidt ind i vaeggen (undgaar ugyldig geometri)
function soejler() = [
  [vaeg + post_d/2 - soejle_ind,          vaeg + post_d/2 - soejle_ind],
  [ud_x - vaeg - post_d/2 + soejle_ind,   vaeg + post_d/2 - soejle_ind],
  [vaeg + post_d/2 - soejle_ind,          ud_y - vaeg - post_d/2 + soejle_ind],
  [ud_x - vaeg - post_d/2 + soejle_ind,   ud_y - vaeg - post_d/2 + soejle_ind]
];
stand_hul_dyb = min(insert_len + 0.5, stand_h + bund_t - 1);   // blindhul i standoff (1 mm bund tilbage)
soejle_hul_dyb = insert_len + 1.5;                              // blindhul i hjoernesoejle (fra toppen)

// KiCad (x,y) -> boks-koordinater (y spejlet, set oppefra)
function bx(x) = vaeg + luft + pad + x;
function by(y) = vaeg + luft + (pcb_y - y);

module bund() {
  difference() {
    union() {
      difference() {
        cube([ud_x, ud_y, bund_t + ind_h]);
        translate([vaeg, vaeg, bund_t]) cube([ind_x, ind_y, ind_h + 1]);
      }
      for (h = hullet)
        translate([bx(h[0]), by(h[1]), bund_t]) cylinder(d = 7, h = stand_h, $fn = 40);
      // Hjoernesoejler i fuld hoejde, sidder fast i vaeggene
      for (p = soejler())
        translate([p[0], p[1], bund_t]) cylinder(d = post_d, h = ind_h, $fn = 40);
    }
    // Insert-huller i standoffs til print (M3 insert, varmes ned fra toppen)
    for (h = hullet)
      translate([bx(h[0]), by(h[1]), bund_t + stand_h - stand_hul_dyb]) cylinder(d = insert_d, h = stand_hul_dyb + 1, $fn = 30);
    // Insert-huller i hjoernesoejler til laag
    for (p = soejler())
      translate([p[0], p[1], bund_t + ind_h - soejle_hul_dyb]) cylinder(d = insert_d, h = soejle_hul_dyb + 1, $fn = 30);

    z0 = bund_t + stand_h + pcb_t;
    // USB-C paa y=0 kanten (J4 ved x=47.5)
    translate([bx(47.5) - 5, -1, z0 - 0.5]) cube([10, vaeg + luft + 2, 4.5]);
    // Skrueklemmer paa y=54 kanten: J1 (x=50, 2-polet), J2 (x=32, 3-polet)
    translate([bx(50) - 7, ud_y - vaeg - luft - 1, z0]) cube([14, vaeg + luft + 2, 10]);
    translate([bx(32) - 10, ud_y - vaeg - luft - 1, z0]) cube([20, vaeg + luft + 2, 10]);
    // SMA-boesning gennem endevaeggen ved x=0
    translate([-1, by(sma_y), z0 + sma_z_over_print]) rotate([0, 90, 0])
      difference() {
        cylinder(d = sma_hul_d, h = vaeg + 2, $fn = 48);
        if (sma_flad > 0) translate([-sma_hul_d, sma_flad, -1]) cube([2*sma_hul_d, sma_hul_d, vaeg + 4]);
      }
  }
}

module laag() {
  difference() {
    union() {
      cube([ud_x, ud_y, laag_t]);
      translate([vaeg + 0.2, vaeg + 0.2, -2]) cube([ind_x - 0.4, ind_y - 0.4, 2]);
    }
    // Udsparinger i fligen omkring hjoernesoejlerne, og M3 gennemgangshul i laaget
    for (p = soejler()) {
      translate([p[0], p[1], -3]) cylinder(d = post_d + 0.6, h = 3, $fn = 40);
      translate([p[0], p[1], -3]) cylinder(d = 3.4, h = laag_t + 4, $fn = 30);
    }
    // LED'er: D4 groen (x=42,y=22), D5 roed (x=42,y=25)
    translate([bx(42), by(22), -3]) cylinder(d = 3, h = laag_t + 4, $fn = 30);
    translate([bx(42), by(25), -3]) cylinder(d = 3, h = laag_t + 4, $fn = 30);
    // Knapper SW1 BOOT (x=36,y=11.5) og SW2 RESET (x=4.5,y=38)
    translate([bx(36), by(11.5), -3]) cylinder(d = 3, h = laag_t + 4, $fn = 30);
    translate([bx(4.5), by(38), -3]) cylinder(d = 3, h = laag_t + 4, $fn = 30);
  }
}

if (del == "bund" || del == "begge") bund();
// Laaget vendes saa pladen ligger paa printbordet og fligen peger op (intet under z=0)
if (del == "laag" || del == "begge") translate([0, ud_y + 10, laag_t]) mirror([0, 0, 1]) laag();
