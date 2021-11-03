package scripts_test

import (
	"fmt"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"bytes"
	"encoding/json"
	"io/ioutil"
	"net"
	"os"
	"os/exec"
	"path/filepath"
)

var _ = Describe("VPC peering", func() {

	var KEY_NAMES = []string{"peer_name", "account_id", "vpc_id", "subnet_cidr"}
	var ENV_NAMES = []string{"dev", "prod", "staging"}
	var REGION_NAMES = []string{"eu-west-1", "eu-west-2"}

	Describe("config files", func() {
		var files []string

		BeforeEach(func() {
			files, _ = filepath.Glob("../*.vpc_peering.json")
		})

		It("have all required values", func() {
			for _, filename := range files {
				file, _ := ioutil.ReadFile(filename)

				var peers []map[string]string
				err := json.Unmarshal([]byte(file), &peers)
				Expect(err).To(BeNil(), "Config file: %s", filename)

				for _, peer := range peers {
					for _, v := range KEY_NAMES {
						Expect(peer).To(HaveKeyWithValue(v, Not(BeEmpty())), "Config %s missing %s", filename, v)
					}
				}
			}
		})

		It("do not have intersecting CIDRs", func() {
			for _, filename := range files {
				file, _ := ioutil.ReadFile(filename)

				var peers []map[string]string
				err := json.Unmarshal([]byte(file), &peers)
				Expect(err).To(BeNil(), "Config file: %s", filename)

				var nets []*net.IPNet
				for _, peer := range peers {
					_, net, err := net.ParseCIDR(peer["subnet_cidr"])
					Expect(err).To(BeNil(), "Config file: %s", filename)

					for _, othernet := range nets {
						intersection := (net.Contains(othernet.IP) || othernet.Contains(net.IP))
						Expect(intersection).To(Equal(false), "%s has intersecting CIDRs: %s, %s", filename, net, othernet)
					}
					nets = append(nets, net)
				}
			}
		})

		// The range 10.0.0.0/16 is used by our VPC and 10.255.0.0/16
		// is used by the cf-networking stack for private apps.
		It("do not use the 10.0.0.0/8 range for peers", func() {
			for _, filename := range files {
				file, _ := ioutil.ReadFile(filename)

				var peers []map[string]string
				err := json.Unmarshal([]byte(file), &peers)
				Expect(err).To(BeNil(), "Config file: %s", filename)

				_, reservedRange0, err := net.ParseCIDR("10.0.0.0/16")
				Expect(err).NotTo(HaveOccurred())
				_, reservedRange255, err := net.ParseCIDR("10.255.0.0/16")
				Expect(err).NotTo(HaveOccurred())

				reservedRanges := []*net.IPNet{
					reservedRange0,
					reservedRange255,
				}

				for _, peer := range peers {
					_, net, err := net.ParseCIDR(peer["subnet_cidr"])
					Expect(err).To(BeNil(), "Config file: %s", filename)

					for _, reservedRange := range reservedRanges {
						intersection := (net.Contains(reservedRange.IP) || reservedRange.Contains(net.IP))
						Expect(intersection).To(Equal(false), "%s has intersecting CIDRs: %s, %s", filename, net, reservedRange)
					}
				}
			}
		})

		Describe("do not intersect with any reserved subnets", func() {
			for _, region := range REGION_NAMES {
				for _, envName := range ENV_NAMES {
					It("for a "+envName+" type deployment in "+region, func() {
						infraCidrs, err := terraformFindInfraCIDRs(region, envName)
						Expect(err).ToNot(HaveOccurred())

						var infraNets []*net.IPNet
						for _, cidr := range infraCidrs {
							_, net, err := net.ParseCIDR(cidr)
							Expect(err).ToNot(HaveOccurred(), "Invalid CIDR: %s", cidr)

							infraNets = append(infraNets, net)
						}

						for _, filename := range files {
							file, _ := ioutil.ReadFile(filename)

							var peers []map[string]string
							err := json.Unmarshal([]byte(file), &peers)
							Expect(err).ToNot(HaveOccurred(), "Config file: %s", filename)

							for _, peer := range peers {
								_, peerNet, err := net.ParseCIDR(peer["subnet_cidr"])
								peerName := peer["peer_name"]
								Expect(err).ToNot(HaveOccurred(), "Config file: %s", filename)

								for _, infraNet := range infraNets {
									intersection := (peerNet.Contains(infraNet.IP) || infraNet.Contains(peerNet.IP))
									Expect(intersection).To(Equal(false), "Peer CIDR %s (%s) intersects with infra CIDR %s", peerNet, peerName, infraNet)
								}
							}
						}
					})
				}
			}
		})

		Describe("ops file", func() {
			It("can be generated", func() {
				for _, filename := range files {
					command := exec.Command("./generate_vpc_peering_opsfile.rb", filename)
					var out bytes.Buffer
					command.Stdout = &out
					err := command.Run()
					Expect(err).To(BeNil(), "Config file: %s", filename)
					Expect(out.String()).ToNot(BeEmpty(), "Config file: %s", filename)
					Expect(out.String()).ToNot(Equal(`--- []
`), "Config file: %s", filename)
				}
			})
		})
	})

	Describe("generate_vpc_peering_opsfile.rb", func() {
		var examplePeerConfig map[string]string

		BeforeEach(func() {
			examplePeerConfig = map[string]string{
				"peer_name":   "cheese",
				"account_id":  "123cheese",
				"vpc_id":      "vpc123cheese",
				"subnet_cidr": "0.0.0.0/32",
			}
		})

		Context("ops file", func() {
			It("has no operations with no environment config", func() {
				command := exec.Command("./generate_vpc_peering_opsfile.rb", "cheese")
				var out bytes.Buffer
				command.Stdout = &out
				err := command.Run()
				Expect(err).To(BeNil())
				Expect(out.String()).To(Equal(`--- []
`))
			})

			It("generates one operation per config", func() {
				file, err := ioutil.TempFile(os.TempDir(), "vpcpeer")
				Expect(err).To(BeNil())

				defer os.Remove(file.Name())

				data, _ := json.Marshal([]interface{}{examplePeerConfig})
				err = ioutil.WriteFile(file.Name(), data, 0644)
				Expect(err).To(BeNil())

				command := exec.Command("./generate_vpc_peering_opsfile.rb", file.Name())
				var out bytes.Buffer
				command.Stdout = &out
				err = command.Run()
				Expect(err).To(BeNil())
				Expect(out.String()).To(Equal(`---
- type: replace
  path: "/instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/security_group_definitions?/-"
  value:
    name: vpc_peer_cheese
    rules:
    - protocol: all
      destination: 0.0.0.0/32
`))
			})

			It("crashes when not given a config", func() {
				command := exec.Command("./generate_vpc_peering_opsfile.rb")
				err := command.Run()
				Expect(err).ToNot(BeNil())
			})

			It("crashes when a field is missing", func() {
				for field, _ := range examplePeerConfig {
					var config = map[string]string{}
					for k, v := range examplePeerConfig {
						if k == field {
							continue
						}
						config[k] = v
					}

					file, err := ioutil.TempFile(os.TempDir(), "vpcpeer")
					Expect(err).To(BeNil())

					defer os.Remove(file.Name())

					data, _ := json.Marshal(config)
					err = ioutil.WriteFile(file.Name(), data, 0644)
					Expect(err).To(BeNil())

					command := exec.Command("./generate_vpc_peering_opsfile.rb", file.Name())
					var out bytes.Buffer
					command.Stdout = &out
					err = command.Run()
					Expect(err).ToNot(BeNil(), "Missing field: %s", field)
				}
			})
		})
	})
})

func terraformFindInfraCIDRs(region string, envName string) ([]string, error) {
	// This bash expression with the two extra `sed` calls in needed because#
	// `terraform console` outputs an array of strings like
	//     "[\"10.0.0.0/24\",\"10.0.1.0/24\",\"10.0.2.0/24\"]"
	//
	// We can only parse it as JSON when it's in the format
	//     ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
	//
	// This was a change in behaviour between 0.13.x and 0.14.x
	cmdText := fmt.Sprintf(`echo "jsonencode(values(var.infra_cidrs))" | terraform console -var-file %s.tfvars -var-file %s.tfvars | sed ' s/\\//g' | sed 's/"\(.*\)"$/\1/'`, region, envName)
	cmd := exec.Command("bash", "-c", cmdText)

	stdOut := bytes.Buffer{}
	stdErr := bytes.Buffer{}
	cmd.Stdout = &stdOut
	cmd.Stderr = &stdErr

	cmd.Env = os.Environ()
	cmd.Dir = "../"

	err := cmd.Run()
	if err != nil {
		return nil, fmt.Errorf("%s", string(stdErr.Bytes()))
	}

	var cidrs []string
	err = json.Unmarshal(stdOut.Bytes(), &cidrs)
	if err != nil {
		return nil, err
	}

	return cidrs, nil
}
