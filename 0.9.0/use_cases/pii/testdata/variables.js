// testdata/variables.js
module.exports = {
  cc_regex: {
    data: `\b(?:\d[ -]*){11,15}(\d{4})\b`
  },
  cc_template: {
    data: "****-****-****-$1",
  },
  email_regex: {
    data: `\b([a-zA-Z0-9._%+-]{3})[a-zA-Z0-9._%+-]*@([a-zA-Z0-9]{2})[a-zA-Z0-9.-]*\.(\w{2,})\b`,
  },
  email_template: { data: "$1***@$2**.***" },

  phone_regex: {
    data: `\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?(\d{4})\b`,
  },
  phone_template: { data: "***-***-$1" },

  ssn_regex: {
    data: `\b\d{3}-\d{2}-(\d{4})\b`
  },
  ssn_template: { data: "***-**-$1" },
  fields_to_hash: { data: ["email", "phone", "ssn", "address"] },
  fields_to_redact: { data: ["email", "phone", "ssn", "address", "cc"] },
};
