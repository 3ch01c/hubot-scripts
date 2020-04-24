"use strict";

const HttpsProxyAgent = require("https-proxy-agent");
const _ = require("lodash");
const { DateTime } = require("luxon");
const util = require("util");
const moreutil = require("./lib/moreutil.js");

// Description
//   Get COVID-19 statistics
//
// Dependencies:
//   "https-proxy-agent": "^5.0.0",
//   "lodash": "^4.17.15",
//   "luxon": "^1.22.2",
//
// Commands:
//   hubot covid (country|state|county) (current|historical) order <field> (asc|desc) limit <number> <region name> - get statistics on COVID-19 outbreak
//
// Author:
//   3ch01c <5547581+3ch01c@users.noreply.github.com>

const HTTP_PROXY = process.env.HTTP_PROXY;

module.exports = async function (robot) {
  let cache;
  if (robot.brain != null)
    robot.brain.on("loaded", () => {
      cache = robot.brain.get("covid19") || [];
    });
  else cache = robot.brain.get("covid19") || [];

  class Model {
    dates = [];

    constructor({ dates = [] }) {
      this.dates = dates;
    }

    setDate(date) {
      let i = _.findIndex(this.dates, date == date.date);
      if (i == -1) {
        this.dates.push(date);
      } else {
        this.dates[i] = date;
      }
    }

    getDate(date) {
      return _.find(this.dates, date == date);
    }
  }

  class Country {
    regions = [];

    constructor({}) {}

    setRegion({}) {}
  }

  class Region {
    constructor({}) {}
  }

  class State extends Region {
    regions = [];

    constructor({}) {}

    setRegion({}) {
      this.regions.push(region);
    }
  }

  class County extends Region {
    constructor({}) {}

    setHospital({}) {}
  }

  class APIRequest {
    httpOptions = {};

    constructor({
      regionType,
      dataType,
      orderBy,
      limit = 7,
      resultFormat,
      filter,
      bucketBy,
      records = [],
    }) {
      this.regionType = regionType;
      this.dataType = dataType;
      this.orderBy = orderBy;
      this.limit = limit;
      this.resultFormat = resultFormat;
      this.filter = filter;
      this.bucketBy = bucketBy;
      this.records = records;
    }
  }

  class JHUAPIRequest extends APIRequest {
    acknowledgement =
      "This COVID-19 data is curated by [JHU CSSE](https://systems.jhu.edu/).";
    apiVersion = "Nc2JKvYFoAEOFCG5JSI6";
    apiBase = `https://services9.arcgis.com/N9p5hsImWXAccRNI/arcgis/rest/services/${this.apiVersion}/FeatureServer`;
    apis = {
      country: {
        historical: `${this.apiBase}/4`,
        current: `${this.apiBase}/2`,
      },
      state: {
        current: `${this.apiBase}/3`,
      },
      county: {
        current: `${this.apiBase}/1`,
      },
    };
    regionKeys = {
      country: "Country_Region",
      state: "State_Province",
      county: "Admin2",
    };
    httpOptions = {
      headers: {
        referer:
          "https://gisanddata.maps.arcgis.com/apps/opsdashboard/index.html",
      },
    };

    constructor({
      regionType = "country",
      dataType = "current",
      orderBy = "Last_Update desc,Confirmed desc",
      limit,
      resultFormat,
      filter,
      records,
    }) {
      super({
        regionType,
        dataType,
        orderBy,
        limit,
        resultFormat,
        filter,
        records,
      });
      let api = this.apis[regionType][dataType];
      if (api == null) {
        throw Error(`No API for ${regionType} ${dataType}, yet.`);
      }
      let query;
      if (this.filter != null)
        query = this.Query({
          where: `${this.regionKeys[regionType]} = '${filter}'`,
        });
      else query = this.Query({});
      this.apiUrl = `${api}/query?${query}`;
      console.log(this);
    }

    Query({
      f = "json",
      where = "Confirmed > 0",
      outFields = "*",
      orderByFields = this.orderBy,
      resultRecordCount = this.limit,
    }) {
      return serialize({
        f: f,
        where: where,
        outFields: outFields,
        orderByFields: orderByFields,
        resultRecordCount: resultRecordCount,
      });
    }

    fromAPIResponse(body) {
      JSON.parse(body).features.map((feature) => {
        let record = feature.attributes;
        return {
          county: record.Admin2,
          state: record.Province_State,
          country: record.Country_Region,
          date: DateTime.fromMillis(record.Last_Update).toISODate(),
          tests: {
            positive: {
              cumulative: {
                absolute: record.Confirmed,
              },
              delta: {
                absolute: record.Delta_Confirmed,
                normal: normalize(record.Delta_Confirmed, record.Confirmed),
              },
            },
            cumulative: {
              absolute: record.People_Tested,
            },
          },
          outcomes: {
            died: {
              cumulative: {
                absolute: record.Deaths,
                normal: normalize(record.Deaths, record.Confirmed),
              },
            },
            recovered: {
              cumulative: {
                absolute: record.Recovered,
                normal: normalize(record.Recovered, record.Confirmed),
              },
              delta: {
                absolute: record.Delta_Recovered,
                normal: normalize(
                  record.Delta_Recovered,
                  record.Delta_Confirmed
                ),
              },
            },
          },
        };
      });
      if (this.resultFormat == "json") return this.toJSON();
      else return this.toTable();
    }

    toTable() {
      let columnNames = [
        "Region",
        "Positive",
        "ΔPositive (per 100 positive)",
        "Died (per 100 positive)",
        "Recovered (per 100 positive)",
        "Tested",
        "Date",
      ];
      let tableHeader = columnNames.join(" | ");
      let tableSeparator = columnNames
        .map(() => {
          return "---";
        })
        .join(" | ");
      let tableRows = this.records
        .map((record) => {
          return `${record.county ? record.county + ", " : ""}${
            record.state ? record.state + ", " : ""
          }${record.country} | ${record.tests.positive.cumulative.absolute} | ${
            record.tests.positive.delta.normal
          } | ${record.outcomes.died.cumulative.normal} | ${
            record.outcomes.recovered.cumulative.normal
          } | ${record.tests.cumulative.absolute} | ${record.date}`;
        })
        .join("\n");
      let table = [tableHeader, tableSeparator, tableRows].join("\n");
      return [this.acknowledgement, "\n", table].join("\n");
    }

    toJSON() {
      return "\n```json\n" + JSON.stringify(this.records) + "\n```";
    }
  }

  class COVIDTrackingAPIRequest extends APIRequest {
    acknowledgement =
      "This data is curated by [The COVID Tracking Project](https://covidtracking.com/about-team/).";
    apiBase = "https://covidtracking.com/api";
    apis = {
      state: {
        current: `${this.apiBase}/states`,
        historical: `${this.apiBase}/states/daily`,
        info: `${this.apiBase}/states/info`,
        urls: `${this.apiBase}/urls`,
      },
      country: {
        current: `${this.apiBase}/us`,
        historical: `${this.apiBase}/us/daily`,
      },
      county: `${this.apiBase}/counties`,
      press: `${this.apiBase}/press`,
    };

    constructor({
      regionType = "state",
      dataType = "historical",
      orderBy = "date desc,tests.completed.cumulative.absolute desc",
      limit,
      resultFormat,
      filter,
      records,
    }) {
      // convert orderBy string into [lodash
      // orderBy](https://lodash.com/docs/4.17.15#orderBy) parameters
      let fields = [],
        orders = [];
      orderBy.split(",").forEach((o) => {
        let field, order;
        [field, order] = o.split(" ");
        fields.push(field);
        orders.push(order);
      });
      orderBy = {
        fields: fields,
        orders: orders,
      };

      super({
        regionType,
        dataType,
        orderBy,
        limit,
        resultFormat,
        filter,
        records,
      });

      // covid tracking api url is in the form of https://covidtracking.com/api/states/daily?state=NY
      let apiUrl = this.apis[regionType][dataType];
      if (filter != null) apiUrl = `${apiUrl}?${this.Query(filter)}`;
      this.apiUrl = apiUrl;
    }

    Query(state) {
      return serialize({
        state: state,
      });
    }

    fromAPIResponse(body) {
      JSON.parse(body).forEach((result) => {
        let date = DateTime.fromISO(result.date).toISODate();
        let state = {
          name: result.state,
          tests: {
            positive: {
              cumulative: result.positive,
              today: result.positiveIncrease,
            },
            negative: {
              cumulative: result.negative,
              today: result.negativeIncrease,
            },
            pending: {
              today: result.pending,
            },
          },
          outcomes: {
            hospitalized: {
              cumulative: result.hospitalized,
              today: result.hospitalizedCurrently,
              inICU: {
                cumulative: result.inIcuCumulative,
                today: result.inIcuCurrently,
              },
              onVentilator: {
                cumulative: result.onVentilatorCumulative,
                today: result.onVentilatorCurrently,
              },
            },
            died: {
              cumulative: result.death,
              today: result.deathIncrease,
            },
            recovered: {
              cumulative: result.recovered,
            },
          },
        };
        let dateIndex = _.findIndex(this.records, (o) => {
          o.date == date;
        });
        if (dateIndex == -1) {
          // create a new entry
          this.records.push({
            date: date,
            countries: [{ name: "US", states: [state] }],
          });
        } else {
          // add state to existing entry
          this.records[dateIndex].countries[0].states.push(state);
        }
      });
      return this.records;
    }

    toTable() {
      let columnNames = [
        "Region",
        "Positive (per 100 tested)",
        "ΔPositive (per 100 positive)",
        "Hospitalized (per 100 positive)",
        "ΔHospitalized (per 100 hospitalized)",
        "Died (per 100 positive)",
        "ΔDied (per 100 died)",
        "Tested",
        "Date",
      ];
      let tableHeader = columnNames.join(" | ");
      let tableSeparator = columnNames
        .map(() => {
          return "---";
        })
        .join(" | ");
      let tableRows = _.orderBy(
        _.filter(this.records, function (o) {
          return o.tests.completed.cumulative.absolute > 0;
        }),
        this.orderBy.fields,
        this.orderBy.orders
      )
        .slice(0, this.limit)
        .map((record) => {
          return `${record.name} | ${record.tests.positive.cumulative.normal} | ${record.tests.positive.delta.normal} | ${record.outcomes.hospitalized.cumulative.normal} | ${record.outcomes.hospitalized.delta.normal} | ${record.outcomes.died.cumulative.normal} | ${record.outcomes.died.delta.normal} | ${record.tests.completed.cumulative.absolute} | ${record.date}`;
        })
        .join("\n");
      let table = [tableHeader, tableSeparator, tableRows].join("\n");
      return [this.acknowledgement, "\n", table].join("\n");
    }

    toJSON() {
      return "\n```json\n" + JSON.stringify(this.records) + "\n```";
    }
  }

  robot.respond(/covid19 update/i, async (msg) => {
    let match = msg.match;
    console.log(JSON.stringify(match));
    msg.reply(`Updating COVID-19 data...`);
    try {
      let request = new COVIDTrackingAPIRequest({
        regionType: "state",
        dataType: "historical",
        limit: 5000,
      });
      request.records = cache;
      let get = moreutil.getAsync(
        robot.http(request.apiUrl, request.httpOptions)
      );
      cache = request.fromAPIResponse(await get);
      console.log(
        cache.length,
        _.minBy(cache, "date").date,
        _.maxBy(cache, "date").date
      );
      msg.reply("Finished updating COVID-19 data");
    } catch (e) {
      console.log(e);
      msg.reply(e);
    }
  });

  robot.respond(
    /((What is the|How many) ((transmission|death)(s| rate))) (of|from) (COVID-19)(( in( the)? (US))?|( by (state)))+\??/i,
    (msg) => {
      let match = res.match;
      console.log(JSON.stringify(match));
      let functor = match[2], // How many
        attribute = match[3], // deaths
        dataset = match[7], // COVID-19
        where = match[10]; // US
      if (matchValue == "US" && bucketBy == "state") {
        msg.reply("Not implemented yet.");
      }
    }
  );
};
