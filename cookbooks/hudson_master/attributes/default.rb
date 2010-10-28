hudson({
  :master => {
    :host => "ec2-174-129-24-134.compute-1.amazonaws.com",
    :port => 80
  },
  :gem => {
    :install => "hudson --pre",
    :version => "hudson-0.3.0.beta.9"
  }
})