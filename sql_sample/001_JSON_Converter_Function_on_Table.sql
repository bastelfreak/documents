﻿--- Create Table ---

DROP table if exists measurement_master;

create table measurement_master
(
	id bigint not null,
	metadata json not null,
	data json not null
);

--- Create Function ---

DROP function if exists convert_input_data_to_json_cpu_table(integer);

CREATE OR REPLACE FUNCTION public.convert_input_data_to_json_cpu_table(integer)
  RETURNS character AS $BODY$
DECLARE
	r log%ROWTYPE;

	id_count integer := 0;
 BEGIN
	truncate table measurement_master;

	FOR r IN
		SELECT *
		FROM log l
		ORDER BY l."timestamp"
		LIMIT $1
	LOOP
		INSERT INTO measurement_master VALUES (id_count,
				json_build_object(
					'insert_at', current_timestamp::timestamp,
					'aggregation_type', 'seconds'),
				json_build_object(
					'host',r.host,
					'timestamp',r."timestamp",
					'plugin',r.plugin,
					'type_instance',r.type_instance,
					'collectd_type',r.collectd_type,
					'plugin_instance',r.plugin_instance,
					'type',r.type,
					'value',r.value,
					'version',r.version)
				);
		id_count := id_count + 1;
	END LOOP;
	
	return 'Running ' || id_count || ' Times!';
	--- Do not user '. Times!' -> the point tells postgresSQL, that the string is a table-column
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.convert_input_data_to_json_cpu_table(integer)
  OWNER TO metrics;

--- Test Function ---

select convert_input_data_to_json_cpu_table(1000000);


-- DO NOT RUN THIS WITHOUT LIMIT -> Y SOFTWARE WILL CRASH
select * from measurement_master LIMIT 10;
SELECT id, data->>'host' AS name FROM measurement_master LIMIT 10;
-- data->'timestamps'->>'timestamp_one'
-- CREATE UNIQUE INDEX cpu_data_hostname ON cpu ((data->'host'));
-- SELECT data->>'host' AS hosts, count(hosts)
-- SUM(CAST(data->>'value' AS integer))