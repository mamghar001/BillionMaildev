require ["fileinto", "mailbox"];

if anyof (
  header :contains "Subject" "[ref:",
  exists "X-Warmy-ID"
) {
  fileinto :create "Warmup";
  stop;
}

