TODO:
 - Consider how runKW can be modified to include multiple buckets by resolving ids. Is it desirable to have one interpreter for all buckets, or an interpreter for each bucket?
 - Error messages can be a bit lacking:
     `tweak 1 2 3`
  yields
     `error => invalid lifetime`
  Is the following more desirable?
     `error => invalid lifetime, 
     details => "2 3" is invalid`
