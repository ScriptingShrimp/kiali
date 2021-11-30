package virtualservices

import (
	"testing"

	"github.com/stretchr/testify/assert"
	networking_v1alpha3 "istio.io/client-go/pkg/apis/networking/v1alpha3"

	"github.com/kiali/kiali/config"
	"github.com/kiali/kiali/kubernetes"
	"github.com/kiali/kiali/models"
	"github.com/kiali/kiali/tests/data"
	"github.com/kiali/kiali/tests/testutils/validations"
)

func TestValidHost(t *testing.T) {
	assert := assert.New(t)

	vals, valid := NoHostChecker{
		Namespace:      "test-namespace",
		ServiceNames:   []string{"reviews", "other"},
		VirtualService: *data.CreateVirtualService(),
	}.Check()

	assert.True(valid)
	assert.Empty(vals)
}

func TestNoValidHost(t *testing.T) {
	conf := config.NewConfig()
	config.Set(conf)

	assert := assert.New(t)

	virtualService := data.CreateVirtualService()

	vals, valid := NoHostChecker{
		Namespace:      "test-namespace",
		ServiceNames:   []string{"details", "other"},
		VirtualService: *virtualService,
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)
	assert.Equal(models.ErrorSeverity, vals[0].Severity)
	assert.NoError(validations.ConfirmIstioCheckMessage("virtualservices.nohost.hostnotfound", vals[0]))
	assert.Equal("spec/http[0]/route[0]/destination/host", vals[0].Path)
	assert.Equal(models.ErrorSeverity, vals[1].Severity)
	assert.NoError(validations.ConfirmIstioCheckMessage("virtualservices.nohost.hostnotfound", vals[1]))
	assert.Equal("spec/tcp[0]/route[0]/destination/host", vals[1].Path)

	virtualService.Spec.Http = nil

	vals, valid = NoHostChecker{
		Namespace:      "test-namespace",
		ServiceNames:   []string{"details", "other"},
		VirtualService: *virtualService,
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)
	assert.Equal(models.ErrorSeverity, vals[0].Severity)
	assert.NoError(validations.ConfirmIstioCheckMessage("virtualservices.nohost.hostnotfound", vals[0]))
	assert.Equal("spec/tcp[0]/route[0]/destination/host", vals[0].Path)

	virtualService.Spec.Tcp = nil

	vals, valid = NoHostChecker{
		Namespace:      "test-namespace",
		ServiceNames:   []string{"details", "other"},
		VirtualService: *virtualService,
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)
	assert.Equal(models.ErrorSeverity, vals[0].Severity)
	assert.NoError(validations.ConfirmIstioCheckMessage("virtualservices.nohost.invalidprotocol", vals[0]))
	assert.Equal("", vals[0].Path)
}

func TestInvalidServiceNamespaceFormatHost(t *testing.T) {
	conf := config.NewConfig()
	config.Set(conf)

	assert := assert.New(t)

	virtualService := data.AddTcpRoutesToVirtualService(data.CreateTcpRoute("reviews.outside-namespace", "v1", -1),
		data.CreateEmptyVirtualService("reviews", "test", []string{"reviews"}),
	)

	vals, valid := NoHostChecker{
		Namespace: "test-namespace",
		Namespaces: models.Namespaces{
			models.Namespace{Name: "test"},
			models.Namespace{Name: "outside-namespace"},
		},
		ServiceNames:   []string{"details", "other"},
		VirtualService: *virtualService,
	}.Check()

	assert.True(valid)
	assert.NotEmpty(vals)
	assert.Equal(models.Unknown, vals[0].Severity)
	assert.NoError(validations.ConfirmIstioCheckMessage("validation.unable.cross-namespace", vals[0]))
	assert.Equal("spec/tcp[0]/route[0]/destination/host", vals[0].Path)
}

func TestValidServiceEntryHost(t *testing.T) {
	conf := config.NewConfig()
	config.Set(conf)

	assert := assert.New(t)

	virtualService := data.CreateVirtualServiceWithServiceEntryTarget()

	vals, valid := NoHostChecker{
		Namespace:      "wikipedia",
		ServiceNames:   []string{"my-wiki-rule"},
		VirtualService: *virtualService,
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)

	// Add ServiceEntry for validity
	serviceEntry := data.CreateExternalServiceEntry()

	vals, valid = NoHostChecker{
		Namespace:         "wikipedia",
		ServiceNames:      []string{"my-wiki-rule"},
		VirtualService:    *virtualService,
		ServiceEntryHosts: kubernetes.ServiceEntryHostnames([]networking_v1alpha3.ServiceEntry{serviceEntry}),
	}.Check()

	assert.True(valid)
	assert.Empty(vals)
}

func TestValidWildcardServiceEntryHost(t *testing.T) {
	conf := config.NewConfig()
	config.Set(conf)

	assert := assert.New(t)

	virtualService := data.AddHttpRoutesToVirtualService(data.CreateHttpRouteDestination("www.google.com", "v1", -1),
		data.CreateEmptyVirtualService("googleIt", "google", []string{"www.google.com"}))

	vals, valid := NoHostChecker{
		Namespace:      "google",
		ServiceNames:   []string{"duckduckgo"},
		VirtualService: *virtualService,
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)

	// Add ServiceEntry for validity
	serviceEntry := data.CreateEmptyMeshExternalServiceEntry("googlecard", "google", []string{"*.google.com"})

	vals, valid = NoHostChecker{
		Namespace:         "google",
		ServiceNames:      []string{"duckduckgo"},
		VirtualService:    *virtualService,
		ServiceEntryHosts: kubernetes.ServiceEntryHostnames([]networking_v1alpha3.ServiceEntry{*serviceEntry}),
	}.Check()

	assert.True(valid)
	assert.Empty(vals)
}

func TestValidServiceRegistry(t *testing.T) {
	conf := config.NewConfig()
	config.Set(conf)

	assert := assert.New(t)

	virtualService := data.AddHttpRoutesToVirtualService(
		data.CreateHttpRouteDestination("ratings.mesh2-bookinfo.svc.mesh1-imports.local", "v1", -1),
		data.CreateEmptyVirtualService("federation-vs", "bookinfo", []string{"*"}))

	vals, valid := NoHostChecker{
		Namespace:      "bookinfo",
		ServiceNames:   []string{""},
		VirtualService: *virtualService,
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)

	registryService := kubernetes.RegistryService{}
	registryService.Hostname = "ratings.mesh2-bookinfo.svc.mesh1-imports.local"
	vals, valid = NoHostChecker{
		Namespace:        "bookinfo",
		ServiceNames:     []string{""},
		VirtualService:   *virtualService,
		RegistryServices: []*kubernetes.RegistryService{&registryService},
	}.Check()

	assert.True(valid)
	assert.Empty(vals)

	registryService = kubernetes.RegistryService{}
	registryService.Hostname = "ratings2.mesh2-bookinfo.svc.mesh1-imports.local"
	vals, valid = NoHostChecker{
		Namespace:        "bookinfo",
		ServiceNames:     []string{""},
		VirtualService:   *virtualService,
		RegistryServices: []*kubernetes.RegistryService{&registryService},
	}.Check()

	assert.False(valid)
	assert.NotEmpty(vals)
}
