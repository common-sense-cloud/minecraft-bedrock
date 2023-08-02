const compute = require('@google-cloud/compute');
const zone = "us-east1-b";
const project = "terraform-basics-12"
const instance = "mc-server-v1";
const fwname = 'minecraft-fw-rule-owner';

 


exports.stopInstance = async function stopInstance(req, res) {

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
    console.log("Stopping Minecraft Server...")
    const InstancesClient = new compute.InstancesClient()
    const request = {
      instance,
      zone,
      project
    }

    InstancesClient.stop(request)
  // Cleanup firewall rule
    // const firewall = fwname
    // let fwRequest = {
    //   firewall,
    //   project
    // }
    // FirewallClient.delete(fwRequest)
    // console.log(`Firewall rule: ${fwname} Deleted`)

  } else {
    console.log("server is already stopped")
    res.send("Server is already stopped! Nothing to do.")
  }
  res.status(200).send('Minecraft Server Stopped!' );

 } catch(e){
  console.log("Error checking server status!", e)
  res.status(500).send(e)
 }


};