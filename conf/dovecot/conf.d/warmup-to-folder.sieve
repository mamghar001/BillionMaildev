require ["fileinto", "mailbox", "body"];

if anyof (
  exists "X-SP-WUP",
  exists "X-SP-RFS",
  header :contains "X-SP-WUP" "1",
  header :contains "Subject" "[ref:",
  header :contains "Subject" "Strachka",
  header :contains "Subject" "straska",
  body :contains "Strachka",
  body :contains "straska",
  exists "X-Warmy-ID",
  exists "X-Mail-Warmup",
  exists "X-Smartlead-Warmup",
  exists "X-Instantly-Warmup"
) {
  fileinto :create "Warmup";
  stop;
}

