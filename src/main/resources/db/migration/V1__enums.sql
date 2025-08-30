SET
search_path TO logistics, public;

CREATE TYPE role_type AS ENUM ('SHIPPER', 'CONSIGNEE', 'PAYER');
CREATE TYPE mode AS ENUM ('ROAD', 'AIR', 'SEA');
CREATE TYPE entity_type AS ENUM ('ORDER', 'CONSIGNMENT', 'SHIPMENT', 'LEG');
CREATE TYPE stop_role AS ENUM ('PICKUP','DELIVERY');
