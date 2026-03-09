import { AxiosError, AxiosResponse } from 'axios';
import http, { handleError, Problem, UUID } from '@/http';
import { subDays } from 'date-fns';
import type { components } from '@/types';

type definitions = components['schemas'];

export type RequestAttempt = definitions['RequestAttempt'];
export type Response = definitions['Response'];

export const enum RequestAttemptStatusType {
  Waiting = 'waiting',
  Pending = 'pending',
  InProgress = 'inprogress',
  Successful = 'successful',
  Failed = 'failed',
}

export type RequestAttemptStatus = {
  type: RequestAttemptStatusType;
};

type Modify<T, R> = Omit<T, keyof R> & R;

export type RequestAttemptTypeFixed = Modify<RequestAttempt, { status: RequestAttemptStatus }>;

export function list(application_id: UUID): Promise<Array<RequestAttemptTypeFixed>> {
  return http
    .get('/request_attempts', {
      params: {
        application_id: application_id,
        min_created_at: subDays(new Date(), 7).toISOString(),
      },
    })
    .then(
      (res: AxiosResponse<Array<RequestAttemptTypeFixed>>) => res.data,
      (err: AxiosError<AxiosResponse<Problem>>) => Promise.reject(handleError(err))
    );
}

export function getResponse(response_id: UUID, application_id: UUID): Promise<Response> {
  return http
    .get(`/responses/${response_id}`, {
      params: {
        application_id: application_id,
      },
    })
    .then(
      (res: AxiosResponse<Response>) => res.data,
      (err: AxiosError<AxiosResponse<Problem>>) => Promise.reject(handleError(err))
    );
}
