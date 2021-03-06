# lvs/configuration.pp

class lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1001', 'lvs1004', 'lvs1007', 'lvs1010' ],
                'codfw' => [ 'lvs2001', 'lvs2004' ],
                'esams' => [ 'lvs3001', 'lvs3003' ],
                'ulsfo' => [ 'lvs4001', 'lvs4003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1002', 'lvs1005', 'lvs1008', 'lvs1011' ],
                'codfw' => [ 'lvs2002', 'lvs2005' ],
                'esams' => [ 'lvs3002', 'lvs3004' ],
                'ulsfo' => [ 'lvs4002', 'lvs4004' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1003', 'lvs1006', 'lvs1009', 'lvs1012' ],
                'codfw' => [ 'lvs2003', 'lvs2006' ],
                'esams' => [ ],
                'ulsfo' => [ ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
    }

    if $::ipaddress6_eth0 {
        $v6_ip = $::ipaddress6_eth0
    }
    else {
        $v6_ip = '::'
    }

    # NOTE: This is for informational purposes only. The actual configuration
    # that decides primary/secondary is done at the BGP level on the routers.
    $lvs_grain = $::hostname ? {
        /^lvs100[123789]$/ => 'primary',
        /^lvs200[123]$/    => 'primary',
        /^lvs[34]00[12]$/  => 'primary',
        default => 'secondary'
    }

    # This is technically redundant information from $lvs_class_hosts, but
    # transforming one into the other in puppet is a huge PITA.
    $lvs_grain_class = $::hostname ? {
        /^lvs10(07|10)$/  => 'high-traffic1',
        /^lvs10(08|11)$/  => 'high-traffic2',
        /^lvs10(09|12)$/  => 'low-traffic',
        /^lvs[12]00[14]$/ => 'high-traffic1',
        /^lvs[12]00[25]$/ => 'high-traffic2',
        /^lvs[12]00[36]$/ => 'low-traffic',
        /^lvs[34]00[13]$/ => 'high-traffic1',
        /^lvs[34]00[24]$/ => 'high-traffic2',
        default           => 'unknown',
    }

    $pybal = {
        'bgp' => hiera('lvs::configuration::bgp', 'yes'),
        'bgp-peer-address' => $::hostname ? {
            /^lvs100[1-3]$/ => '208.80.154.196', # cr1-eqiad
            /^lvs100[4-6]$/ => '208.80.154.197', # cr2-eqiad
            /^lvs100[789]$/ => '208.80.154.196', # cr1-eqiad
            /^lvs101[012]$/ => '208.80.154.197', # cr2-eqiad
            /^lvs200[1-3]$/ => '208.80.153.192', # cr1-codfw
            /^lvs200[4-6]$/ => '208.80.153.193', # cr2-codfw
            /^lvs300[12]$/  => '91.198.174.244',  # cr2-esams
            /^lvs300[34]$/  => '91.198.174.245',  # cr1-esams
            /^lvs400[12]$/  => '198.35.26.192',   # cr1-ulsfo
            /^lvs400[34]$/  => '198.35.26.193',   # cr2-ulsfo
            default         => '(unspecified)'
            },
        'bgp-nexthop-ipv4' => $::ipaddress_eth0,
        # FIXME: make a Puppet function, or fix facter
        'bgp-nexthop-ipv6' => inline_template("<%= require 'ipaddr'; (IPAddr.new(@v6_ip).mask(64) | IPAddr.new(\"::\" + scope.lookupvar(\"::ipaddress\").gsub('.', ':'))).to_s() %>"),
        'instrumentation' => 'yes',
    }

    # NOTE! This hash is referenced in many other manifests
    $service_ips = hiera('lvs::configuration::lvs_service_ips')
    $lvs_services = hiera('lvs::configuration::lvs_services')

    $subnet_ips = {
        'public1-a-eqiad' => {
            'lvs1004' => '208.80.154.58',
            'lvs1005' => '208.80.154.59',
            'lvs1006' => '208.80.154.60',
            'lvs1007' => '208.80.154.43',
            'lvs1008' => '208.80.154.44',
            'lvs1009' => '208.80.154.45',
            'lvs1010' => '208.80.154.46',
            'lvs1011' => '208.80.154.47',
            'lvs1012' => '208.80.154.48',
        },
        'public1-b-eqiad' => {
            'lvs1001' => '208.80.154.140',
            'lvs1002' => '208.80.154.141',
            'lvs1003' => '208.80.154.142',
            'lvs1007' => '208.80.154.161',
            'lvs1008' => '208.80.154.162',
            'lvs1009' => '208.80.154.163',
            'lvs1010' => '208.80.154.164',
            'lvs1011' => '208.80.154.165',
            'lvs1012' => '208.80.154.166',
        },
        'public1-c-eqiad' => {
            'lvs1001' => '208.80.154.78',
            'lvs1002' => '208.80.154.68',
            'lvs1003' => '208.80.154.69',
            'lvs1004' => '208.80.154.70',
            'lvs1005' => '208.80.154.71',
            'lvs1006' => '208.80.154.72',
            'lvs1007' => '208.80.154.96',
            'lvs1008' => '208.80.154.97',
            'lvs1009' => '208.80.154.98',
            'lvs1010' => '208.80.154.99',
            'lvs1011' => '208.80.154.100',
            'lvs1012' => '208.80.154.101',
        },
        'public1-d-eqiad' => {
            'lvs1001' => '208.80.155.100',
            'lvs1002' => '208.80.155.101',
            'lvs1003' => '208.80.155.102',
            'lvs1004' => '208.80.155.103',
            'lvs1005' => '208.80.155.104',
            'lvs1006' => '208.80.155.105',
            'lvs1007' => '208.80.155.111',
            'lvs1008' => '208.80.155.112',
            'lvs1009' => '208.80.155.113',
            'lvs1010' => '208.80.155.114',
            'lvs1011' => '208.80.155.115',
            'lvs1012' => '208.80.155.116',
        },
        'private1-a-eqiad' => {
            'lvs1001' => '10.64.1.1',
            'lvs1002' => '10.64.1.2',
            'lvs1003' => '10.64.1.3',
            'lvs1004' => '10.64.1.4',
            'lvs1005' => '10.64.1.5',
            'lvs1006' => '10.64.1.6',
            'lvs1010' => '10.64.1.10',
            'lvs1011' => '10.64.1.11',
            'lvs1012' => '10.64.1.12',
        },
        'private1-b-eqiad' => {
            'lvs1001' => '10.64.17.1',
            'lvs1002' => '10.64.17.2',
            'lvs1003' => '10.64.17.3',
            'lvs1004' => '10.64.17.4',
            'lvs1005' => '10.64.17.5',
            'lvs1006' => '10.64.17.6',
            'lvs1007' => '10.64.17.7',
            'lvs1008' => '10.64.17.8',
            'lvs1009' => '10.64.17.9',
            'lvs1010' => '10.64.17.10',
            'lvs1011' => '10.64.17.11',
            'lvs1012' => '10.64.17.12',
        },
        'private1-c-eqiad' => {
            'lvs1001' => '10.64.33.1',
            'lvs1002' => '10.64.33.2',
            'lvs1003' => '10.64.33.3',
            'lvs1004' => '10.64.33.4',
            'lvs1005' => '10.64.33.5',
            'lvs1006' => '10.64.33.6',
            'lvs1007' => '10.64.33.7',
            'lvs1008' => '10.64.33.8',
            'lvs1009' => '10.64.33.9',
        },
        'private1-d-eqiad' => {
            'lvs1001' => '10.64.49.1',
            'lvs1002' => '10.64.49.2',
            'lvs1003' => '10.64.49.3',
            'lvs1004' => '10.64.49.4',
            'lvs1005' => '10.64.49.5',
            'lvs1006' => '10.64.49.6',
            'lvs1007' => '10.64.49.7',
            'lvs1008' => '10.64.49.8',
            'lvs1009' => '10.64.49.9',
            'lvs1010' => '10.64.49.10',
            'lvs1011' => '10.64.49.11',
            'lvs1012' => '10.64.49.12',
        },
        'public1-a-codfw' => {
            'lvs2001' => '208.80.153.6',
            'lvs2002' => '208.80.153.7',
            'lvs2003' => '208.80.153.8',
            'lvs2004' => '208.80.153.9',
            'lvs2005' => '208.80.153.10',
            'lvs2006' => '208.80.153.11',
        },
        'public1-b-codfw' => {
            'lvs2001' => '208.80.153.39',
            'lvs2002' => '208.80.153.40',
            'lvs2003' => '208.80.153.41',
            'lvs2004' => '208.80.153.36',
            'lvs2005' => '208.80.153.37',
            'lvs2006' => '208.80.153.38',
        },
        'public1-c-codfw' => {
            'lvs2001' => '208.80.153.68',
            'lvs2002' => '208.80.153.69',
            'lvs2003' => '208.80.153.70',
            'lvs2004' => '208.80.153.71',
            'lvs2005' => '208.80.153.72',
            'lvs2006' => '208.80.153.73',
        },
        'public1-d-codfw' => {
            'lvs2001' => '208.80.153.100',
            'lvs2002' => '208.80.153.101',
            'lvs2003' => '208.80.153.102',
            'lvs2004' => '208.80.153.103',
            'lvs2005' => '208.80.153.104',
            'lvs2006' => '208.80.153.105',
        },
        'private1-a-codfw' => {
            'lvs2004' => '10.192.1.4',
            'lvs2005' => '10.192.1.5',
            'lvs2006' => '10.192.1.6',
        },
        'private1-b-codfw' => {
            'lvs2001' => '10.192.17.1',
            'lvs2002' => '10.192.17.2',
            'lvs2003' => '10.192.17.3',
        },
        'private1-c-codfw' => {
            'lvs2001' => '10.192.33.1',
            'lvs2002' => '10.192.33.2',
            'lvs2003' => '10.192.33.3',
            'lvs2004' => '10.192.33.4',
            'lvs2005' => '10.192.33.5',
            'lvs2006' => '10.192.33.6',
        },
        'private1-d-codfw' => {
            'lvs2001' => '10.192.49.1',
            'lvs2002' => '10.192.49.2',
            'lvs2003' => '10.192.49.3',
            'lvs2004' => '10.192.49.4',
            'lvs2005' => '10.192.49.5',
            'lvs2006' => '10.192.49.6',
        },
        'public1-esams' => {
            'lvs3001' => '91.198.174.11',
            'lvs3002' => '91.198.174.12',
            'lvs3003' => '91.198.174.13',
            'lvs3004' => '91.198.174.14',
        },
    }
}
