require ["fileinto", "mailbox"];

if anyof (
  header :contains "Subject" "Automatic reply",
  header :contains "Subject" "Auto reply",
  header :contains "Subject" "autoresponse",
  header :contains "Subject" "Out of Office",
  header :contains "Subject" "Autoreply"
) {
  fileinto :create "Automatic Replies";
  stop;
}
