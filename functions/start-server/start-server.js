/**
* Start the Minecraft server, return the external IP, and create a FW rule
*/
const compute = require('@google-cloud/compute');
const zone = "us-east1-b";
const project = "terraform-basics-12"
const instance = "mc-server-v1";
const fwname = 'minecraft-fw-rule-owner';
 
async function get_server_ip() {
  const InstancesClient = new compute.InstancesClient()
  const request = {
    instance,
    zone,
    project
  }

  let request_array = await InstancesClient.get(request)
 return request_array[0].networkInterfaces[0].accessConfigs[0].natIP
}
 
async function check_if_server_is_ready() {
 const server_ip = await get_server_ip();
 const ready = !!server_ip;
 return ready
}
 
async function sleep(milliseconds) {
 return new Promise(function(resolve, reject) {
   setTimeout(resolve, milliseconds);
 });
}
 
exports.startInstance = async function startInstance(req, res) {

 // Check if server is already running
 console.log("Checking server status...")
 let serverStatus
 try{
  const InstancesClient = new compute.InstancesClient()
  const request = {
    instance,
    zone,
    project
  }

  let request_array = await InstancesClient.get(request)
  serverStatus = request_array[0].status

  if (serverStatus === "RUNNING") {
    const server_ip = await get_server_ip()
    console.log("Server is already running!")
    res.send(`Server is already running at ${server_ip}!`)
    return
  }
 } catch(e){
  console.log("Error checking server status!", e)
 }
 // Start the VM
 try {
  console.log('about to start a VM');
  const InstancesClient = new compute.InstancesClient()
  const request = {
    instance,
    zone,
    project
  }

  InstancesClient.start(request)
  console.log('the server is starting');
  while(!(await check_if_server_is_ready())) {
    console.log('Server is not ready, waiting 1 second...');
    await sleep(1000);
    console.log('Checking server readiness again...');
  }
  console.log('the server is ready');
  const server_ip = await get_server_ip();

  // Record the function caller's IPv4 address
  console.log(JSON.stringify(req.headers));
  sourceIp = req.get('X-Forwarded-For');
  let callerip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;

  
  try{
  
  const FirewallClient = new compute.FirewallsClient()
  // Check if FW rule already exsists
  // const firewall = fwname
  // let request = {
  //   firewall,
  //   project
  // }
  // let ownerFirewall = await FirewallClient.get(request)
  // console.log(ownerFirewall)
  
  // if (ownerFirewall.sourceRanges.contains("98.97.80.116/32")){
  //   console.log("Firewall rule for this user already exists!")
  //   res.send(`FW Rule already exists for ${callerip}, Server IP: ${server_ip}!`)
  //   return
  // }
  
    // Set the Firewall configs
    const firewallResource = {
      name: fwname,
      sourceRanges: [`104.179.45.103/32`],
      allowed: [
        {
          IPProtocol: "udp",
          ports: ["19132"]
        }
      ],
      direction: "INGRESS",
      targetTags: ["minecraft-server"]
    };

    let test = {
      firewallResource,
      project
    }
    
    
    // Create the Firewall
   FirewallClient.insert(test)
   console.log("Firewall rule created")
  } catch(e) {
    console.log("Error: Could not add firewall policy rule!", e)
    res.status(500).send(e)
  }
  
  res.status(200).send('Minecraft Server Started! You are now spending REAL MONEY! <br />' + 'The IP address of the Minecraft server is: ' + server_ip + ':19132<br />Your IP address is ' + callerip + '<br />A Firewall rule named ' + fwname + ' has been created for you.' );

 } catch(e){
  console.log("Failed to start VM!", e)
 }
 
 
};