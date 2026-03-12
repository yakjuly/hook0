<script setup lang="ts">
import { ColDef } from 'ag-grid-community';
import { onMounted, onUpdated, ref } from 'vue';
import { useRoute } from 'vue-router';

import Hook0Button from '@/components/Hook0Button.vue';
import Hook0CardContentLine from '@/components/Hook0CardContentLine.vue';
import Hook0CardContent from '@/components/Hook0CardContent.vue';
import Hook0CardContentLines from '@/components/Hook0CardContentLines.vue';
import Hook0CardHeader from '@/components/Hook0CardHeader.vue';
import Hook0Card from '@/components/Hook0Card.vue';
import Hook0Table from '@/components/Hook0Table.vue';
import Hook0TableCellLink from '@/components/Hook0TableCellLink.vue';
import Hook0TableCellDate from '@/components/Hook0TableCellDate.vue';
import Hook0TableCellIcon from '@/components/Hook0TableCellIcon.vue';
import { UUID } from '@/http';
import Hook0Text from '@/components/Hook0Text.vue';
import * as EventsService from './EventsService';
import { EventWithPayload } from './EventsService';
import * as LogService from '../logs/LogService';
import { RequestAttemptStatusType, RequestAttemptTypeFixed } from '../logs/LogService';
import Hook0Code from '@/components/Hook0Code.vue';
import Hook0DateTime from '@/components/Hook0DateTime.vue';
import Hook0Loader from '@/components/Hook0Loader.vue';
import Hook0Error from '@/components/Hook0Error.vue';
import { routes } from '@/routes';

const route = useRoute();

const event$ = ref<Promise<Array<EventWithPayload>>>();
const attempts$ = ref<Promise<Array<RequestAttemptTypeFixed>>>();
const event_id = ref<null | UUID>(null);
const application_id = ref<null | UUID>(null);

const attemptColumnDefs: ColDef[] = [
  {
    field: 'status',
    suppressMovable: true,
    suppressSizeToFit: true,
    width: 75,
    sortable: true,
    headerName: 'Status',
    cellRenderer: Hook0TableCellIcon,
    cellRendererParams: {
      title(row: RequestAttemptTypeFixed) {
        switch (row.status.type) {
          case RequestAttemptStatusType.Waiting:
            return 'Request scheduled for later';
          case RequestAttemptStatusType.Pending:
            return 'Request waiting to be picked';
          case RequestAttemptStatusType.InProgress:
            return 'Request is currently being sent';
          case RequestAttemptStatusType.Failed:
            return 'Request had an error';
          case RequestAttemptStatusType.Successful:
            return 'Request successfully sent';
          default:
            return 'Unknown status';
        }
      },
      icon(row: RequestAttemptTypeFixed) {
        switch (row.status.type) {
          case RequestAttemptStatusType.Waiting:
            return 'fa-calendar';
          case RequestAttemptStatusType.Pending:
            return 'fa-pause';
          case RequestAttemptStatusType.InProgress:
            return 'fa-spinner';
          case RequestAttemptStatusType.Failed:
            return 'fa-xmark';
          case RequestAttemptStatusType.Successful:
            return 'fa-check';
          default:
            return 'fa-question';
        }
      },
    },
    valueFormatter: () => 'unreachable',
  },
  {
    field: 'response_id',
    suppressMovable: true,
    suppressSizeToFit: true,
    width: 100,
    sortable: false,
    resizable: false,
    headerName: 'Response',
    cellRenderer: Hook0TableCellLink,
    cellRendererParams: {
      value(row: RequestAttemptTypeFixed) {
        return row.response_id ? 'View' : '';
      },
      to(row: RequestAttemptTypeFixed) {
        if (!row.response_id) {
          return null;
        }
        return {
          name: routes.LogsDetail,
          params: {
            application_id: route.params.application_id,
            organization_id: route.params.organization_id,
            event_id: row.event_id,
            response_id: row.response_id,
          },
        };
      },
    },
  },
  {
    field: 'subscription id',
    suppressMovable: true,
    suppressSizeToFit: false,
    width: 150,
    sortable: true,
    resizable: true,
    headerName: 'Subscription',
    cellRenderer: Hook0TableCellLink,
    cellRendererParams: {
      value(row: RequestAttemptTypeFixed) {
        return row.subscription.description;
      },
      to(row: RequestAttemptTypeFixed) {
        return {
          name: routes.SubscriptionsDetail,
          params: {
            application_id: route.params.application_id,
            organization_id: route.params.organization_id,
            subscription_id: row.subscription.subscription_id,
          },
        };
      },
    },
  },
  {
    field: 'created_at',
    suppressMovable: true,
    suppressSizeToFit: true,
    width: 175,
    sortable: true,
    sort: 'desc',
    resizable: true,
    headerName: 'Created At',
    cellRenderer: Hook0TableCellDate,
  },
  {
    field: 'picked_at',
    suppressMovable: true,
    suppressSizeToFit: true,
    width: 175,
    sortable: true,
    resizable: true,
    headerName: 'Picked At',
    cellRenderer: Hook0TableCellDate,
    cellRendererParams: {
      defaultText: 'pending…',
    },
  },
];

function _load() {
  if (
    event_id.value !== route.params.event_id ||
    application_id.value !== route.params.application_id
  ) {
    event_id.value = route.params.event_id as UUID;
    application_id.value = route.params.application_id as UUID;

    event$.value = EventsService.get(event_id.value, application_id.value).then();
    attempts$.value = LogService.listByEventId(application_id.value, event_id.value);
  }
}

onMounted(() => {
  _load();
});

onUpdated(() => {
  _load();
});
</script>

<template>
  <Promised :promise="event$">
    <!-- Use the "pending" slot to display a loading message -->
    <template #pending>
      <Hook0Loader></Hook0Loader>
    </template>

    <template #rejected="error">
      <Hook0Error :error="error"></Hook0Error>
    </template>

    <template #default="event">
      <div data-test="event-detail-page">
        <Hook0Card data-test="event-detail-card">
          <Hook0CardHeader>
            <template #header>
              Event of type
              <Hook0Text class="code" data-test="event-detail-type">{{
                event.event_type_name
              }}</Hook0Text>
            </template>
            <template #subtitle>
              <Hook0Text class="block">
                <Hook0Text class="label pr-1">Event ID:</Hook0Text>
                <Hook0Text class="code">{{ event.event_id }}</Hook0Text>
              </Hook0Text>

              <Hook0Text class="block">
                <Hook0Text class="label pr-1">Occurred At:</Hook0Text>
                <Hook0DateTime :value="event.occurred_at"></Hook0DateTime>
              </Hook0Text>

              <Hook0Text class="block">
                <Hook0Text class="label pr-1">Received At:</Hook0Text>
                <Hook0DateTime :value="event.received_at"></Hook0DateTime>
              </Hook0Text>

              <Hook0Text class="block">
                <Hook0Text class="label pr-1">Source IP:</Hook0Text>
                <Hook0Text class="code">{{ event.ip }}</Hook0Text>
              </Hook0Text>
            </template>
          </Hook0CardHeader>
        </Hook0Card>

        <Hook0Card>
          <Hook0CardHeader>
            <template #header> Metadata </template>
            <template #subtitle>
              <Hook0Button href="https://documentation.hook0.com/docs/metadata" class="label pr-1"
                >Learn more…</Hook0Button
              >
            </template>
          </Hook0CardHeader>
          <Hook0CardContent>
            <template v-if="event.metadata !== null && Object.keys(event.metadata).length > 0">
              <Hook0CardContentLine v-for="(value, key) in event.metadata" :key="key">
                <template #label>{{ key }}</template>
                <template #content>
                  <Hook0Text class="code">{{ value }}</Hook0Text>
                </template>
              </Hook0CardContentLine>
            </template>
            <template v-else>
              <Hook0CardContentLine>
                <template #label>No metadata</template>
              </Hook0CardContentLine>
            </template>
          </Hook0CardContent>
        </Hook0Card>
        <Hook0Card>
          <Hook0CardHeader>
            <template #header>Labels</template>
            <template #subtitle></template>
          </Hook0CardHeader>
          <Hook0CardContent>
            <Hook0CardContentLine v-for="(value, key) in event.labels" :key="key">
              <template #label>{{ key }}</template>
              <template #content>
                <Hook0Text class="code">{{ value }}</Hook0Text>
              </template>
            </Hook0CardContentLine>
          </Hook0CardContent>
        </Hook0Card>

        <Hook0Card>
          <Hook0CardHeader>
            <template #header> Payload </template>
            <template #subtitle></template>
          </Hook0CardHeader>
          <Hook0CardContent>
            <Hook0CardContentLine>
              <template #label> Payload Content Type </template>
              <template #content>
                <Hook0Text class="code">{{ event.payload_content_type }}</Hook0Text>
              </template>
            </Hook0CardContentLine>
            <Hook0CardContentLine>
              <template #label> Payload (decoded) </template>
              <template #content>
                <Hook0Code :code="event.payload_decoded" />
              </template>
            </Hook0CardContentLine>
          </Hook0CardContent>
        </Hook0Card>

        <Promised :promise="attempts$">
          <template #pending>
            <Hook0Card>
              <Hook0CardHeader>
                <template #header>Request Attempts</template>
              </Hook0CardHeader>
              <Hook0CardContent>
                <Hook0Loader></Hook0Loader>
              </Hook0CardContent>
            </Hook0Card>
          </template>

          <template #rejected="attemptsError">
            <Hook0Card>
              <Hook0CardHeader>
                <template #header>Request Attempts</template>
              </Hook0CardHeader>
              <Hook0CardContent>
                <Hook0Error :error="attemptsError"></Hook0Error>
              </Hook0CardContent>
            </Hook0Card>
          </template>

          <template #default="attempts">
            <Hook0Card data-test="event-attempts-card">
              <Hook0CardHeader>
                <template #header>Request Attempts</template>
                <template #subtitle> Webhook delivery attempts for this event. </template>
              </Hook0CardHeader>

              <Hook0CardContent v-if="attempts.length > 0">
                <Hook0Table
                  data-test="event-attempts-table"
                  :context="{ attempts$, columnDefs: attemptColumnDefs }"
                  :column-defs="attemptColumnDefs"
                  :row-data="attempts"
                  row-id-field="request_attempt_id"
                >
                </Hook0Table>
              </Hook0CardContent>

              <Hook0CardContent v-else>
                <Hook0CardContentLines>
                  <Hook0CardContentLine type="full-width">
                    <template #content>
                      <Hook0Text class="center block" style="text-align: center">
                        No delivery attempts found for this event.
                      </Hook0Text>
                    </template>
                  </Hook0CardContentLine>
                </Hook0CardContentLines>
              </Hook0CardContent>
            </Hook0Card>
          </template>
        </Promised>
      </div>
    </template>
  </Promised>
</template>
