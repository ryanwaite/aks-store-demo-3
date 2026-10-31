extension radius

param environment string

@secure()
param registryPassword string

@secure()
param registryUsername string

param storeAdminHostname string = 'store-admin.localhost'
param storeFrontHostname string = 'store-front.localhost'

resource aksStoreDemoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'aks-store-demo-3'
  properties: {
    environment: environment
  }
}

resource mongoDb 'Radius.Data/mongoDatabases@2025-08-01-preview' = {
  name: 'mongo'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/makeline-service/mongodb.go#L127'
    database: 'orderdb'
  }
}

resource rabbitmqQueue 'Radius.Messaging/rabbitMQ@2025-08-01-preview' = {
  name: 'rabbitmq'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/order-service/plugins/messagequeue.js#L26'
    queue: 'orders'
    username: 'myadmin'
  }
}

// Do not change this Secret's name value from 'radius-ghcr-registry-creds'.
// The containerImages recipe looks up registry credentials by that fixed name.
resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: '.radius/app.bicep#L44'
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource makelineServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'makeline-service-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/makeline-service/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/makeline-service?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource orderServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'order-service-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/order-service/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/order-service?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource productServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'product-service-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/product-service/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/product-service?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource storeAdminImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'store-admin-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/store-admin/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/store-admin?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource storeFrontImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'store-front-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/store-front/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/store-front?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource virtualCustomerImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'virtual-customer-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/virtual-customer/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/virtual-customer?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource virtualWorkerImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'virtual-worker-image'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/virtual-worker/Dockerfile'
    build: {
      source: 'git::https://github.com/ryanwaite/aks-store-demo-3.git//src/virtual-worker?ref=d752f0b4f7edc22159c7529a6cd7956099b6d819'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource makelineServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'makeline-service'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/makeline-service/main.go#L21'
    containers: {
      makelineService: {
        image: makelineServiceImage.properties.imageReference
        env: {
          ORDER_DB_COLLECTION_NAME: {
            value: 'orders'
          }
          ORDER_DB_NAME: {
            value: mongoDb.properties.database
          }
          ORDER_DB_URI: {
            valueFrom: {
              secretKeyRef: {
                secretName: mongoDb.properties.secrets.name
                key: 'connectionString'
              }
            }
          }
          ORDER_QUEUE_NAME: {
            value: rabbitmqQueue.properties.queue
          }
          ORDER_QUEUE_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: rabbitmqQueue.properties.secrets.name
                key: 'password'
              }
            }
          }
          ORDER_QUEUE_URI: {
            value: 'amqp://${rabbitmqQueue.properties.host}:${rabbitmqQueue.properties.port}'
          }
          ORDER_QUEUE_USERNAME: {
            value: rabbitmqQueue.properties.username
          }
        }
        ports: {
          web: {
            containerPort: 3001
          }
        }
        readinessProbe: {
          httpGet: {
            path: '/health'
            port: 3001
          }
        }
      }
    }
  }
}

resource orderServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'order-service'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/order-service/app.js#L6'
    containers: {
      orderService: {
        image: orderServiceImage.properties.imageReference
        env: {
          FASTIFY_ADDRESS: {
            value: '0.0.0.0'
          }
          ORDER_QUEUE_HOSTNAME: {
            value: rabbitmqQueue.properties.host
          }
          ORDER_QUEUE_NAME: {
            value: rabbitmqQueue.properties.queue
          }
          ORDER_QUEUE_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: rabbitmqQueue.properties.secrets.name
                key: 'password'
              }
            }
          }
          ORDER_QUEUE_PORT: {
            value: string(rabbitmqQueue.properties.port)
          }
          ORDER_QUEUE_USERNAME: {
            value: rabbitmqQueue.properties.username
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}

resource productServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'product-service'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/product-service/src/main.rs#L5'
    containers: {
      productService: {
        image: productServiceImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3002
          }
        }
      }
    }
  }
}

resource storeAdminContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'store-admin'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/store-admin/src/main.ts'
    containers: {
      storeAdmin: {
        image: storeAdminImage.properties.imageReference
        command: [
          '/bin/sh'
          '-c'
        ]
        args: [
          '''
set -eu
sed -i -e "s|http://makeline-service:3001|http://$MAKELINE_SERVICE_HOST:3001|g" -e "s|http://order-service:3000|http://$ORDER_SERVICE_HOST:3000|g" -e "s|http://product-service:3002|http://$PRODUCT_SERVICE_HOST:3002|g" /etc/nginx/conf.d/default.conf
exec /docker-entrypoint.sh nginx -g "daemon off;"
'''
        ]
        env: {
          MAKELINE_SERVICE_HOST: {
            value: makelineServiceContainer.properties.hosts['makelineService']
          }
          ORDER_SERVICE_HOST: {
            value: orderServiceContainer.properties.hosts['orderService']
          }
          PRODUCT_SERVICE_HOST: {
            value: productServiceContainer.properties.hosts['productService']
          }
        }
        ports: {
          web: {
            containerPort: 8081
          }
        }
      }
    }
  }
}

resource storeFrontContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'store-front'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/store-front/src/main.ts'
    containers: {
      storeFront: {
        image: storeFrontImage.properties.imageReference
        command: [
          '/bin/sh'
          '-c'
        ]
        args: [
          '''
set -eu
sed -i -e "s|http://order-service:3000|http://$ORDER_SERVICE_HOST:3000|g" -e "s|http://product-service:3002|http://$PRODUCT_SERVICE_HOST:3002|g" /etc/nginx/conf.d/default.conf
exec /docker-entrypoint.sh nginx -g "daemon off;"
'''
        ]
        env: {
          ORDER_SERVICE_HOST: {
            value: orderServiceContainer.properties.hosts['orderService']
          }
          PRODUCT_SERVICE_HOST: {
            value: productServiceContainer.properties.hosts['productService']
          }
        }
        ports: {
          web: {
            containerPort: 8080
          }
        }
      }
    }
  }
}

resource virtualCustomerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'virtual-customer'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/virtual-customer/src/main.rs#L7'
    containers: {
      virtualCustomer: {
        image: virtualCustomerImage.properties.imageReference
        env: {
          ORDERS_PER_HOUR: {
            value: '100'
          }
          ORDER_SERVICE_URL: {
            value: 'http://${orderServiceContainer.properties.hosts['orderService']}:3000/'
          }
        }
      }
    }
  }
}

resource virtualWorkerContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'virtual-worker'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'src/virtual-worker/src/main.rs#L6'
    containers: {
      virtualWorker: {
        image: virtualWorkerImage.properties.imageReference
        env: {
          MAKELINE_SERVICE_URL: {
            value: 'http://${makelineServiceContainer.properties.hosts['makelineService']}:3001'
          }
          ORDERS_PER_HOUR: {
            value: '100'
          }
        }
      }
    }
  }
}

resource storeAdminRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'store-admin-route'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'aks-store-all-in-one.yaml#L501'
    hostnames: [
      storeAdminHostname
    ]
    kind: 'HTTP'
    rules: [
      {
        destinationContainer: {
          containerName: 'storeAdmin'
          containerPort: 8081
          resourceId: storeAdminContainer.id
        }
        matches: [
          {
            httpPath: '/'
          }
        ]
      }
    ]
  }
}

resource storeFrontRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'store-front-route'
  properties: {
    environment: environment
    application: aksStoreDemoApp.id
    codeReference: 'aks-store-all-in-one.yaml#L438'
    hostnames: [
      storeFrontHostname
    ]
    kind: 'HTTP'
    rules: [
      {
        destinationContainer: {
          containerName: 'storeFront'
          containerPort: 8080
          resourceId: storeFrontContainer.id
        }
        matches: [
          {
            httpPath: '/'
          }
        ]
      }
    ]
  }
}
