#
# Cookbook Name:: jenkins_slave
# Recipe:: default
#

jenkins_slave({
  :master => {
    :host => "mysecretapp.com",
    :port => 80,
    :public_key => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtz9dQqsUsUCf1vkk3krI4b2Dxaaiv49/p9/X1xYWYj5rhvRzvBalmBmXydj37ND6wf370b6kYqiUbFY3Dn+gCK5EIBlMrreRYE+tGHwAKKDwOrAkMtLBYtKseTs+SVSWyJwobOiMsyIEyAU1g2cbBwd3MBDcuBb3y9piulVcZevHdnKztgNWoz2oxWemnlQsHcVL31VgnPZQURz9U1MlLn/QAjtRW9xOlXCiTYVEh63svTsWmiPrDKuXAnhicD88jETUnu44WRGcY/ygmlX9b1/KOHm22Vw7jUL+Q9+J+nUXCYXG7pf6t8Ul2NYF+iAoFzCF+cLbmKB6QshcDr6ZLQ== root@ip-10-66-101-144",
    :master_key_location => "/home/deploy/.ssh/id_rsa"
  },
  :gem => {
    :install => "jenkins",
    :version => "jenkins-0.6.4"
  }
})