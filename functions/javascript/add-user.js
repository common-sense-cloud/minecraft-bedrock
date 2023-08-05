/**
* Create the VPC Firewall Rule to allow the function caller to access the Minecraft server
*/
const compute = require('@google-cloud/compute');
const zone = "us-east1-b";
const project = "terraform-basics-12"
const instance = "mc-server-v1";
const fwname = 'minecraft-fw-rule-guest';
const getIP = require("ipware")().get_ip;

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


exports.makeFWRule = function makeFWRule(req, res) { 
  
try{
 // Record the function caller's IPv4 address
 console.log(getIP(req))
 let callerip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
 const server_ip = get_server_ip()
  
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
      sourceRanges: [`${callerip}/32`],
      allowed: [
        {
          IPProtocol: "tcp",
          ports: ["25565"]
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
   res.send(`Firewall rule created, Server IP: ${server_ip}`)
  } catch(e) {
    console.log("Error: Could not add firewall policy rule!", e)
    res.status(500).send(e)
  }
};