package scripts_test

import (
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

				_, reservedRange, _ := net.ParseCIDR("10.0.0.0/8")

				for _, peer := range peers {
					_, net, err := net.ParseCIDR(peer["subnet_cidr"])
					Expect(err).To(BeNil(), "Config file: %s", filename)

					intersection := (net.Contains(reservedRange.IP) || reservedRange.Contains(net.IP))
					Expect(intersection).To(Equal(false), "%s has intersecting CIDRs: %s, %s", filename, net, reservedRange)
				}
			}
		})

		Describe("tfvar output", func() {
			It("can be generated", func() {
				for _, filename := range files {
					command := exec.Command("./generate_vpc_peering_tfvars.rb", filename)
					var out bytes.Buffer
					command.Stdout = &out
					err := command.Run()
					Expect(err).To(BeNil(), "Config file: %s", filename)
					Expect(out.String()).ToNot(BeEmpty(), "Config file: %s", filename)
				}
			})
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

	Describe("generate_vpc_peering_tfvars.rb", func() {
		var examplePeerConfig map[string]string

		BeforeEach(func() {
			examplePeerConfig = map[string]string{
				"peer_name":   "cheese",
				"account_id":  "123cheese",
				"vpc_id":      "vpc123cheese",
				"subnet_cidr": "0.0.0.0/32",
			}
		})

		Context("tfvar output", func() {
			It("is empty with no environment config", func() {
				command := exec.Command("./generate_vpc_peering_tfvars.rb", "cheese")
				var out bytes.Buffer
				command.Stdout = &out
				err := command.Run()
				Expect(err).To(BeNil())
				Expect(out.String()).To(BeEmpty())
			})

			It("crashes when not given a config", func() {
				command := exec.Command("./generate_vpc_peering_tfvars.rb")
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

					command := exec.Command("./generate_vpc_peering_tfvars.rb", file.Name())
					var out bytes.Buffer
					command.Stdout = &out
					err = command.Run()
					Expect(err).ToNot(BeNil(), "Missing field: %s", field)
				}
			})
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
